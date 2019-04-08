### Exports ###

export NConfig, NState, Neurons
export show, size, nupdate!

### Types ###

mutable struct NConfig{S}
  size::S
  a::Float32
  b::Float32
  c::Float32
  d::Float32
  thresh::Float32
  θRate::Float32
  traceRate::Float32
  boostRate::Float32
end
mutable struct NState{RT<:AbstractArray{Float32}, BT<:AbstractArray{Bool}}
  V::RT
  U::RT
  I::RT
  F::BT
  T::RT
  B::RT
  θ::RT
end
mutable struct Neurons{C<:NConfig, S<:NState} <: AbstractNeurons
  conf::C
  state::S
end

NCPUCont{C,S} = CPUContainer{Neurons{C,S}}

### Methods ###

function reinit!(neurons::Neurons)
  fill!(neurons.state.V, neurons.conf.c)
  fill!(neurons.state.U, 0f0)
  fill!(neurons.state.I, 0f0)
  fill!(neurons.state.F, false)
  fill!(neurons.state.T, 0f0)
  fill!(neurons.state.B, 0f0)
  fill!(neurons.state.θ, 0f0)
end
function Base.show(io::IO, neurons::Neurons)
  print(io, "Neurons ($(neurons.conf.size))")
end

Base.size(neurons::Neurons) = neurons.conf.size

@inline function _nupdate!(i, a, b, c, d, thresh, θRate, traceRate, boostRate, V, U, I, F, T, B, θ)
  # Update V and U
  V[i] += 0.5f0 * ((0.04f0 * (V[i] * V[i])) + (5f0 * V[i]) + 140f0 - U[i] + I[i])
  V[i] += 0.5f0 * ((0.04f0 * (V[i] * V[i])) + (5f0 * V[i]) + 140f0 - U[i] + I[i])
  U[i] += a * ((b * V[i]) - U[i])
  #V[i] += -4f0 * (B[i] - 0.8f0)

  # Spike and reset
  F[i] = (V[i] >= thresh + θ[i])
  V[i] += (F[i] * (c - V[i]))
  U[i] += F[i] * d

  # Update θ firing threshold
  θ[i] += F[i] + (θRate * -θ[i] * !F[i])

  # Update traces
  T[i] += F[i] + (traceRate * -T[i] * !F[i])
  #local traceT = fasttanh(T[i])
  #T[i] += traceRate * (((.75f0 - traceT) * F[i]) + ((0.00f0 - traceT) * !F[i]))

  # Update boosts
  # B[i] += boostRate * (T[i] - B[i])

  # Clear inputs
  I[i] = 0f0
end

function nupdate!(neurons::Neurons)
  conf = neurons.conf
  state = neurons.state
  @inbounds @simd for i in eachindex(state.V)
    _nupdate!(i, conf.a, conf.b, conf.c, conf.d, conf.thresh, conf.θRate, conf.traceRate, conf.boostRate, state.V, state.U, state.I, state.F, state.T, state.B, state.θ)
  end
end
nupdate!(ncont::NCPUCont{C,S} where {C,S}) = nupdate!(transient(ncont))
cycle_neurons!(neurons) = nupdate!(neurons)

### Includes ###

include("generic/core.jl")
include("conv/core.jl")
