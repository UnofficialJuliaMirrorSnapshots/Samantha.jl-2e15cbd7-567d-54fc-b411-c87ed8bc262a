### Exports ###

export GenericNConfig, GenericNState, GenericNeurons

### Types ###

GenericNConfig = NConfig{Int}
const GenericNState = NState{Vector{Float32}, Vector{Bool}}
const GenericNeurons = Neurons{GenericNConfig, GenericNState}
GenericNeurons(size::Int; a=0.02, b=0.2, c=-65, d=8, thresh=30, θRate=0.5, traceRate=0.5, boostRate=0.0) =
  GenericNeurons(
    GenericNConfig(
      size,
      a,
      b,
      c,
      d,
      thresh,
      θRate,
      traceRate,
      boostRate),
    GenericNState(
      fill(c, size),
      zeros(Float32, size),
      zeros(Float32, size),
      zeros(Bool, size),
      zeros(Float32, size),
      zeros(Float32, size),
      zeros(Float32, size)))

### Methods ###

function Base.show(io::IO, neurons::GenericNeurons)
  print(io, "GenericNeurons ($(neurons.conf.size))")
end

Base.getindex(neurons::GenericNeurons, idx) =
  neurons.state.F[idx]

# TODO: Make this actually random?
function randnode(::Type{GenericNeurons}, size::Int=rand(1:20))
  GenericNeurons(size)
end
