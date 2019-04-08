### Imports ###

import Base: size, setindex!, getindex, broadcast!, Broadcast.fill!, Broadcast.fill

### Exports ###

export ZeroArray, RingBuffer, AnyNode
export fasttanh, canthread

### Types ###

# Useful type for writing/reading inactive containers efficiently
mutable struct ZeroArray{T, N} <: DenseArray{T, N}
  size::NTuple{N, Int}
end
ZeroArray(T::Type, size::NTuple{N,Int}) where N = ZeroArray{T,N}(size)
ZeroArray(arr::DenseArray{T,N}) where {T,N} = ZeroArray{T,N}(size(arr))

mutable struct RingBuffer{T}
  buf::Matrix{T}
  pos::Int
end
RingBuffer(T, width, length) = RingBuffer(zeros(T, width, length), 1)

# TODO: LockedArray for locking individual arrays

mutable struct AnyNode{T} <: AbstractNode
  item::T
end

### Methods ###

Base.size(za::ZeroArray) = za.size
# TODO: Check for OOB situation?
Base.setindex!(za::ZeroArray{T,N}, value, idx...) where {T,N} = zero(T)
Base.getindex(za::ZeroArray{T,N}, idx...) where {T,N} = zero(T)
# TODO: More broadcast overrides
Base.broadcast!(f, za::ZeroArray{T,N}, args...) where {T,N} = za
Base.Broadcast.fill!(za::ZeroArray{T,N}, value) where {T,N} = za
Base.Broadcast.fill(za::ZeroArray{T,N}, value::T) where {T,N} =
  (value == zero(T) ? za : error("Cannot fill a ZeroArray with a non-zero element"))


function rotate!(rb::RingBuffer)
  if rb.pos < size(rb.buf, 2)
    rb.pos += 1
  else
    rb.pos = 1
  end
end
function _rbindex(rb::RingBuffer, idx)
  @assert 0 <= idx <= size(rb.buf, 2)-1 "Invalid RingBuffer index: $idx"
  npos = rb.pos - idx
  if npos < 1
    npos += size(rb.buf, 2)
  end
  npos
end
Base.getindex(rb::RingBuffer, idx::Int) = getindex(rb.buf, Colon(), _rbindex(rb, idx))
Base.getindex(rb::RingBuffer, ::Colon) = getindex(rb.buf, Colon(), rb.pos)
function Base.getindex(rb::RingBuffer{T}, idx::Vector{Int}) where T
  @assert length(idx) == size(rb.buf, 1) "Invalid RingBuffer indexing vector size: $(length(idx))"
  result = zeros(T, size(rb.buf, 1))
  for i in axes(rb.buf, 1)
    result[i] = rb.buf[i, _rbindex(rb, idx[i])]
  end
  result
end
Base.setindex!(rb::RingBuffer, value, idx::Int) = (rb.buf[:, _rbindex(rb, idx)] .= value)
Base.setindex!(rb::RingBuffer, value, ::Colon) = (rb.buf[:, rb.pos] .= value)
function Base.setindex!(rb::RingBuffer{T}, value::Vector{T}, idx::Vector{Int}) where T
  @assert length(idx) == size(rb.buf, 1) "Invalid RingBuffer indexing vector size: $(length(idx))"
  for i in axes(rb.buf, 1)
    rb.buf[i, _rbindex(rb, idx[i])] = value[i]
  end
end
Base.lastindex(rb::RingBuffer) = size(rb.buf, 2)
clear!(rb::RingBuffer{T}) where T = fill!(rb.buf, zero(T))


# Returns a resized array, with as many existing entries copied as possible
function resize_array(arr::Array{T,N} where {T,N}, new_size::NTuple{N,Int} where N, fill_value=zero(T))
  old_size = size(arr)
  new_arr = fill(fill_value, new_size)
  shared_region = CartesianRange(min.(old_size, new_size))
  copy!(new_arr, shared_region, arr, shared_region)
end

### Miscellaneous Utilities ###

fasttanh(x) = x * ( 27 + x * x ) / ( 27 + 9 * x * x )

canthread() = SAMANTHA_THREADS && !Threads.in_threaded_loop.x && Threads.nthreads() > 1
