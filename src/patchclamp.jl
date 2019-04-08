### Exports ###

export PatchClamp

### Types ###

# TODO: Change dir to be a type parameter
@with_kw struct PatchClamp{A<:AbstractArray} <: AbstractNode
  dir::Symbol
  buffer::A
  conns::Vector{SynapticConnection} = SynapticConnection[]
end
PatchClamp(dir::Symbol, sz::Vararg{Int,N} where N) =
  PatchClamp(dir, Float32, sz...)
PatchClamp(dir::Symbol, typ::Type{T}, sz::Vararg{Int,N} where N) where T =
  PatchClamp(dir=dir, buffer=zeros(T, sz...))

### Methods ###

Base.size(pc::PatchClamp) = size(pc.buffer)
Base.getindex(pc::PatchClamp, idx...) =
  getindex(pc.buffer, idx...)

reinit!(pc::PatchClamp) =
  fill!(pc.buffer, zero(eltype(pc.buffer)))

function addedge!(pc::PatchClamp, dstcont, dst, op, conf)
  @assert first(size(dstcont)) == first(size(pc.buffer)) "Input and output sizes must match"
  @assert pc.dir === :output "PatchClamp is not configured for output"
  if op == :input
    push!(pc.conns, SynapticConnection(dst, op, nothing))
  else
    error("PatchClamp cannot handle op: $op")
  end
end
deledge!(pc::PatchClamp, dst, op) =
  filter!(conn->conn.uuid!==dst, pc.conns)
deledges!(pc::PatchClamp) = empty!(pc.conns)
connections(pc::PatchClamp) = pc.conns

function eforward!(cont::CPUContainer{PC}, args) where PC<:PatchClamp
  pc = root(cont)

  if pc.dir === :output
    pc.buffer .= zero(eltype(pc.buffer))
    for conn in connections(pc)
      cont = args[findfirst(arg->arg[2]==conn.uuid, args)][3]
      inputs = cont[:]
      pc.buffer .+= inputs
    end
  end
end
