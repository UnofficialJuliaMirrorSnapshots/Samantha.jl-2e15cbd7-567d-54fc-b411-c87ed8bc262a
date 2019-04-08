### Exports ###

export SymmetricRuleLearn, PowerLawLearn, ExpWeightDepLearn, ConvSynapses

### Types ###

# TODO: Use Value type to select additional modes?
mutable struct ConvSynapses{L} <: AbstractSynapses
  inputSize::Tuple{Int,Int,Int}
  filterSize::Int
  numFilters::Int
  stride::Int

  learn::L
  
  W::Array{Float32,4}
end
function ConvSynapses(inputSize::Tuple{Int,Int,Int}, filterSize::Int, numFilters::Int, stride::Int=1; learn=SymmetricRuleLearn())
  return ConvSynapses(
    inputSize,
    filterSize,
    numFilters,
    stride,
    learn,
    rand(Float32, inputSize[1], filterSize, filterSize, numFilters) .* 0.3f0
  )
end
ConvSynapses(size::Tuple{Tuple{Int,Int,Int}, Int, Int, Int}; kwargs...) =
  ConvSynapses(size...; kwargs...)

### Methods ###

function clear!(synapses::ConvSynapses)
  rand!(synapses.W, 0f0:0.01f0:0.3f0)
end
# TODO: Make one-liner
function Base.show(io::IO, synapses::ConvSynapses)
  outputSize = output_size(synapses)
  println(io, "ConvSynapses ($(synapses.inputSize) => $(outputSize))")
  println(io, "  Filter Size: $(synapses.filterSize) x $(synapses.filterSize)")
  println(io, "  Stride: $(synapses.stride)")
  println(io, "  Learning Algorithm: $(synapses.learn)")
end
Base.size(cs::ConvSynapses) = (cs.inputSize, cs.filterSize, cs.numFilters, cs.stride)
function output_size(cs::ConvSynapses)
  # FIXME: Stride
  return (cs.inputSize[2]-cs.filterSize+1, cs.inputSize[3]-cs.filterSize+1, cs.numFilters)
end

function update!(f, cs, stride, W, I, G, F, O)
  @inbounds for fj = axes(W, 3)
    @inbounds for fi = axes(W, 2)
      @inbounds for fc = axes(W, 1)
        @inbounds for oj = axes(O, 2)
          @inbounds for oi = axes(O, 1)
            I_ = Float32(I[fc, oi+fi-1, oj+fj-1]) #Float32(I[fc, (stride*(oi-1))+fi, (stride*(oj-1))+fj])

            # Convolve weights with inputs
            O[oi,oj,f] = muladd(W[fc,fi,fj,f], I_, O[oi,oj,f])
          end
        end
      end
    end
  end
end
function learn!(f, cs, stride, W, I, G, F, O)
  lrn = cs.learn
  α_pre, α_post, xtar, Wmax, μ = lrn.α_pre, lrn.α_post, lrn.xtar, lrn.Wmax, lrn.μ
  @inbounds for oj = axes(O, 2)
    @inbounds for oi = axes(O, 1)
      @inbounds for fj = axes(W, 3)
        @inbounds for fi = axes(W, 2)
          @inbounds @simd for fc = axes(W, 1)
            I_ = Float32(I[fc, oi+fi-1, oj+fj-1]) # TODO: Enable stride: Float32(I[fc, (stride*(oi-1))+fi, (stride*(oj-1))+fj])

            # Learn
            W[fc,fi,fj,f] += learn!(cs.learn, I_, G[oi,oj,f], F[oi,oj,f], W[fc,fi,fj,f])
          end
        end
      end
    end
  end
end
# TODO: Specify input and output types
function _eforward!(scont::CPUContainer{S}, input, output) where S<:ConvSynapses
  cs = root(scont)
  stride, W = cs.stride, cs.W

  I = transient(input).data     #@param input[O]
  G = transient(output).state.T #@param output[T]
  F = transient(output).state.F #@param output[F]
  O = transient(output).state.I #@param output[I]
  
  # Clear outputs
  fill!(O, 0f0)

  # Convolve
  @inbounds for f = axes(W, 4)
    update!(f, cs, stride, W, I, G, F, O)
    learn!(f, cs, stride, W, I, G, F, O)
  end

  # Clamp weights
  # TODO: Dispatch on type (or just pull into learn!)
  clamp!(cs.W, 0f0, cs.learn.Wmax)
end
