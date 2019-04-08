### Exports ###

export RewardModulator

### Types ###

mutable struct RewardModulator
  avgInput::Mean
end
RewardModulator() = RewardModulator(Mean(weight=ExponentialWeight()))

### Methods ###

early_modulate!(synapses, mod::Nothing, myconn, conns) = ()
late_modulate!(synapses, mod::Nothing, myconn, conns) = ()

function early_modulate!(synapses, mod::RewardModulator, myconn, conns)
  inputs = myconn[2][:]
  avgInput = mean(inputs)
  rewardModifier = avgInput - value(mod.avgInput)
  fit!(mod.avgInput, avgInput)

  # Update learnRate for each SynapticInput connection
  for conn in filter(conn->conn[1] isa SynapticInput, conns)
    conn[3][:learnRate] *= rewardModifier
  end
end
late_modulate!(synapses, mod::RewardModulator, myconn, conns) = ()

#=
@with_kw mutable struct FunctionalModulator{OF<:Function,IF}
  outer::OF
  inner::IF = nothing
end
modulate!(state, node, mod::FunctionalModulator) = mod.func(modulate!(state, node, mod.inner), node)
=#

#@with_kw mutable struct RewardModulator
#  avgReward::Mean = RewardModulator(Mean(weight=ExponentialWeight()))
#end
#=
function modulate!(state, node::GenericNeurons, mod::RewardModulator)
  rF = node.state.F
  rw = mean(rF)
  #fit!(learnRate, rw-value(mod.avgReward))
  #fit!(mod.avgReward, rw)
  # TODO
end
=#
