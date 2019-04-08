### Exports ###

export HebbianDecayLearn, SymmetricRuleLearn, PowerLawLearn, ExpWeightDepLearn
export BCMLearn

### Types ###

@with_kw mutable struct HebbianDecayLearn
  α::Float32 = 0.01f0
  β::Float32 = 0.9f0
  Wmax::Float32 = 1.0f0
end
@with_kw mutable struct SymmetricRuleLearn
  α_pre::Float32 = 0.1f0
  α_post::Float32 = 0.5f0
  xtar::Float32 = 0.5f0
  Wmax::Float32 = 5f0
  μ::Int = 1f0
end
@with_kw mutable struct PowerLawLearn
  α::Float32 = 0.1f0
  xtar::Float32 = 0.5f0
  Wmax::Float32 = 5f0
  μ::Float32 = 1f0
end
@with_kw mutable struct ExpWeightDepLearn
  α::Float32 = 0.1f0
  xtar::Float32 = 0.5f0
  Wmax::Float32 = 5f0
  μ::Float32 = 1f0
  β::Float32 = 1f0
end
@with_kw mutable struct BCMLearn
  α::Float32 = 0.1f0
  ϵ::Float32 = 1f0
  θM::Matrix{Float32}
  # FIXME: Histories
end

#= TODO
  ## Old algorithms
  # Update weights with modified Oja's rule:
  # Traces as x and gradients as y (temporal averaging)
  #W[n,i] += learnRate * ((T[n,i] * G[n]) - (G[n] * G[n] * W[n,i])) * G[n] * T[n,i] #* (G[n] - T[n,i])
  #W[n,i] += learnRate * (T[n,i] - ((G[n] * W[n,i]) * G[n])) * T[n,i]
  #W[n,i] += learnRate * (T[n,i] * G[n] * (G[n] - W[n,i]))
  #W[n,i] = clamp(W[n,i], 0.01f0, 1f0)
=#

### Methods ###

function learn!(lrn::HebbianDecayLearn, learnRate, I, G, F, W)
  α, β, Wmax = lrn.α, lrn.β, lrn.Wmax
  @inbounds for i = axes(W, 2)
    @inbounds @simd for n = axes(W, 1)
      W[n,i] += learnRate * α * ((F[n] * G[n] * W[n,i]) - (β * W[n,i]))
    end
  end
  clamp!(W, zero(eltype(W)), Wmax)
end

# Article: Unsupervised learning of digit recognition using spike-timing-dependent plasticity
# Authors: Peter U. Diehl and Matthew Cook
function learn!(lrn::SymmetricRuleLearn, learnRate, I, G, F, W)
  α_pre, α_post, xtar, Wmax, μ = lrn.α_pre, lrn.α_post, lrn.xtar, lrn.Wmax, lrn.μ
  @inbounds for i = axes(W, 2)
    @inbounds @simd for n = axes(W, 1)
      W[n,i] += (α_post * F[n] * (I[i] - xtar) * (Wmax - W[n,i]^μ)) - (α_pre * I[i] * G[n] * W[n,i]^μ)
    end
  end
  clamp!(W, zero(eltype(W)), Wmax)
end

# TODO: Inspect both of these:
function learn!(lrn::PowerLawLearn, learnRate, I, G, F, W)
  α, xtar, Wmax, μ = lrn.α, lrn.xtar, lrn.Wmax, lrn.μ
  @inbounds for i = axes(W, 2)
    @inbounds @simd for n = axes(W, 1)
      W[n,i] += learnRate * α * F[n] * (G[n] - xtar) * (Wmax - W[n,i])^μ
    end
  end
  clamp!(W, zero(eltype(W)), Wmax)
end
function learn!(lrn::ExpWeightDepLearn, learnRate, I, G, F, W)
  α, xtar, Wmax, μ, β = lrn.α, lrn.xtar, lrn.Wmax, lrn.μ, lrn.β
  @inbounds for i = axes(W, 2)
    @inbounds @simd for n = axes(W, 1)
      W[n,i] += learnRate * α * F[n] * ((G[n] * exp(-β * W[n,i])) - (xtar * exp(-β * (Wmax - W[n,i]))))
    end
  end
  clamp!(W, zero(eltype(W)), Wmax)
end

function learn!(lrn::BCMLearn, learnRate, I, G, F, W)
  α, ϵ, θM = lrn.α, lrn.ϵ, lrn.θM
  @inbounds for i = axes(W, 2)
    @inbounds @simd for n = axes(W, 1)
      # FIXME
    end
  end
  clamp!(W, zero(eltype(W)), Wmax)
end
