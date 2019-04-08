### Exports ###

export SynapticConnection, SynapticInput

### Types ###

mutable struct SynapticConnection{D}
  uuid::UUID
  op::Symbol
  data::D
end

# FIXME: Support multiple dimensions
@with_kw mutable struct SynapticInput{Frontend,LearnAlg,Mod,NDims}
  inputSize::Int
  outputSize::Int

  condRate::Float32 = 0.1
  traceRate::Float32 = 0.5

  # FIXME: Don't hard-code 16
  frontend::Frontend = GenericFrontend(inputSize, 16)
  learn::LearnAlg = HebbianDecayLearn()
  modulator::Mod = nothing

  C::Array{Float32,NDims} = zeros(Float32, outputSize, inputSize)
  W::Array{Float32,NDims} = rand(Float32, outputSize, inputSize)
  M::Array{Bool,NDims} = ones(Bool, outputSize, inputSize)
  T::Array{Float32,NDims} = zeros(Float32, outputSize, inputSize)
  O::Vector{Float32} = zeros(Float32, outputSize)
end
# FIXME: Apply conf
function SynapticInput(dstcont::CPUContainer, outputSize, conf)
  dstnode = root(dstcont)
  if haskey(conf, :modulator)
    modulator = conf[:modulator]
  else
    modulator = nothing
  end
  SynapticInput(;
    inputSize=first(size(dstnode)),
    outputSize=outputSize,
    modulator=modulator
  )
end

### Methods ###

function reinit!(conn::SynapticInput)
  @unpack frontend, C, W, T = conn
  reinit!(frontend)
  fill!(C, 0f0)
  rand!(W, 0f0:0.01f0:1f0)
  fill!(T, 0f0)
end

### Includes ###

include("learn.jl")
include("modulate.jl")
include("generic.jl")
include("conv.jl")
