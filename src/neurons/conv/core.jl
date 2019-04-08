### Exports ###

export ConvNConfig, ConvNState, ConvNeurons

### Types ###

ConvNConfig = NConfig{Tuple{Int,Int,Int}}
const ConvNState = NState{Array{Float32, 3}, Array{Bool, 3}}
const ConvNeurons = Neurons{ConvNConfig, ConvNState}
ConvNeurons(size::Tuple{Int,Int,Int}; a=0.02, b=0.2, c=-65, d=8, thresh=30, θRate=0.5, traceRate=0.75, boostRate=0.01) =
  ConvNeurons(
    ConvNConfig(
      size,
      a,
      b,
      c,
      d,
      thresh,
      θRate,
      traceRate,
      boostRate),
    ConvNState(
      fill(c, size...),
      zeros(Float32, size...),
      zeros(Float32, size...),
      zeros(Bool, size...),
      zeros(Float32, size...),
      zeros(Float32, size...),
      zeros(Float32, size...)))

### Methods ###

function Base.show(io::IO, neurons::ConvNeurons)
  print(io, "ConvNeurons $(neurons.conf.size)")
end
# TODO: Make this actually random?
function randnode(::Type{ConvNeurons}, size::Tuple{Int,Int,Int}=(rand(1:20,3)...,))
  ConvNeurons(size)
end
