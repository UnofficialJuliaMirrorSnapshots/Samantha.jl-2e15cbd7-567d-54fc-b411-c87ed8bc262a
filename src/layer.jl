### Exports ###

export Layer, GenericLayer

### Types ###

struct Layer{S,N} <: AbstractNode
  synapses::S
  neurons::N
end

const GenericLayer = Layer{GenericSynapses,GenericNeurons}
function GenericLayer(sz::Int)
  Layer(GenericSynapses(sz), GenericNeurons(sz))
end

### Methods ###

addedge!(layer::Layer, dstcont, dst, op, conf) =
  addedge!(layer.synapses, dstcont, dst, op, conf)
deledge!(layer::Layer, dst, op) =
  deledge!(layer.synapses, dst, op)
deledges!(layer::Layer) =
  deledges!(layer.synapses)

function reinit!(layer::Layer)
  reinit!(layer.synapses)
  reinit!(layer.neurons)
end

Base.size(layer::Layer) = size(layer.neurons)

Base.getindex(layer::Layer, idx...) =
  getindex(layer.neurons, idx...)

# ==(layer1::Layer, layer2::Layer) =
#   (layer1.synapses == layer2.synapses) && (layer1.neurons == layer2.neurons)

const ConnWrapper = Tuple{D1, CPUContainer{D2}, Dict{Symbol,Any}} where {D1,D2}

function eforward!(lcont::CPUContainer{Layer{S,N}}, args) where {S,N}
  layer = root(lcont)
  synapses, neurons = layer.synapses, layer.neurons

  # TODO: Sort conns and args by UUID for speed?
  conns = ConnWrapper[]
  for conn in connections(synapses)
    idx = findfirst(arg->arg[2]==conn.uuid, args)
    @assert idx !== nothing
    cont = args[idx][3]
    inputs = cont[:]
    state = Dict{Symbol,Any}()
    state[:inputs] = inputs
    push!(conns, (conn.data, cont, state))
  end

  # Reset run-local variables
  reset_run!(synapses)

  # Initialize connection-local states
  for conn in conns
    initialize_state!(synapses, conn)
  end

  # Get inputs and shift frontends
  for conn in conns
    shift_frontend!(synapses, conn)
  end

  # Early modulation
  for conn in conns
    early_modulate!(synapses, conn, conns)
  end

  # Calculate outputs
  for conn in conns
    calculate_outputs!(synapses, conn)
  end

  # Late modulation
  for conn in conns
    late_modulate!(synapses, conn, conns)
  end

  # Cycle neurons
  for idx in 1:size(neurons)
    # FIXME: Use dispatch properly
    neurons.state.I[idx] = synapses[idx]
  end
  cycle_neurons!(neurons)

  # TODO: Learning modulation?

  # Learn weights
  for conn in conns
    learn_weights!(synapses, conn, neurons)
  end
end

initialize_state!(synapses::GenericSynapses, conn::ConnWrapper) =
  initialize_state!(synapses, conn[1], conn[3])

shift_frontend!(synapses::GenericSynapses, conn::ConnWrapper) =
  shift_frontend!(synapses, conn[1], conn[3][:inputs])

early_modulate!(synapses::GenericSynapses, conn::ConnWrapper, conns) =
  early_modulate!(synapses, conn[1].modulator, conn, conns)

calculate_outputs!(synapses::GenericSynapses, conn::ConnWrapper) =
  calculate_outputs!(synapses, conn[1], conn[3][:inputs])

late_modulate!(synapses::GenericSynapses, conn::ConnWrapper, conns) =
  late_modulate!(synapses, conn[1].modulator, conn, conns)
