### Exports ###

export GenericSynapses, GenericFrontend

### Types ###

mutable struct GenericFrontend
  delayLength::Int

  D::RingBuffer{Bool}
  ID::Vector{Int}
end
GenericFrontend(
  inputSize::Int,
  delayLength::Int,
  delayIndices=(delayLength-1)*ones(inputSize)) =
  GenericFrontend(
    delayLength,
    RingBuffer(Bool, inputSize, delayLength),
    delayIndices
  )

@with_kw mutable struct GenericSynapses <: AbstractSynapses
  outputSize::Int
  outputMask::Float32 = 1.0f0
  O::Vector{Float32} = zeros(Float32, outputSize)
  conns::Vector{SynapticConnection} = SynapticConnection[]
end
GenericSynapses(outputSize) = GenericSynapses(outputSize=outputSize)

### Methods ###

function addedge!(synapses::GenericSynapses, dstcont, dst, op, conf)
  outputSize = synapses.outputSize
  if op == :input
    data = SynapticInput(dstcont, outputSize, conf)
  else
    error("GenericSynapses cannot handle op: $op")
  end
  push!(synapses.conns, SynapticConnection(dst, op, data))
end
deledge!(synapses::GenericSynapses, dst, op) =
  filter!(conn->conn.uuid!==dst, synapses.conns)
deledges!(synapses::GenericSynapses) = empty!(synapses.conns)
function resize!(synapses::GenericSynapses, new_size)
  old_size = size(synapses)
  synapses.inputSize = new_size[1]
  synapses.outputSize = new_size[2]
  synapses.C = resize_arr(synapses.C, new_size)
  synapses.W = resize_arr(synapses.W, new_size)
  synapses.M = resize_arr(synapses.M, new_size)
  synapses.T = resize_arr(synapses.T, new_size)
end
function reinit!(synapses::GenericSynapses)
  for conn in synapses.conns
    reinit!(conn.data)
  end
end
reinit!(frontend::GenericFrontend) = clear!(frontend.D)
Base.size(synapses::GenericSynapses) = synapses.outputSize
connections(synapses::GenericSynapses) = synapses.conns
Base.getindex(synapses::GenericSynapses, idx) =
  getindex(synapses.O, idx)

"Resets run-local variables"
function reset_run!(synapses::GenericSynapses)
  synapses.O .= 0.0
end

"Initializes the input-local state"
function initialize_state!(synapses::GenericSynapses, syni::SynapticInput, state)
  # FIXME
  state[:learnRate] = 1.0f0 #syni.learnRate
end

"Shifts inputs through `frontend`"
shift_frontend!(synapses::GenericSynapses, syni::SynapticInput, inputs) =
  shift_frontend!(syni.frontend, inputs)
function shift_frontend!(frontend::GenericFrontend, inputs)
  rotate!(frontend.D)
  frontend.D[:] = inputs
  return frontend.D[frontend.ID]
end

"Calculate and update the output values for a SynapticInput"
function calculate_outputs!(synapses::GenericSynapses, syni::SynapticInput, inputs)
  @unpack condRate, traceRate = syni
  @unpack C, W, M, T = syni
  O = synapses.O
  @inbounds for i = axes(W, 2)
    @inbounds @simd for n = axes(W, 1)
      # Convolve weights with input
      C[n,i] += M[n,i] * ((W[n,i] * inputs[i]) + (condRate * -C[n,i] * !inputs[i]))
      O[n] += W[n,i] * M[n,i] * C[n,i] * inputs[i]

      # Update traces
      T[n,i] += inputs[i] + (traceRate * -T[n,i] * !inputs[i])
    end
  end
  return O
end

"Update weights for a SynapticInput"
function learn_weights!(synapses::GenericSynapses, conn, neurons::GenericNeurons)
  syni = conn[1]
  inputs = conn[3][:inputs]
  learnRate = conn[3][:learnRate]
  @unpack W, learn = syni
  F, T = neurons.state.F, neurons.state.T

  learn!(learn, learnRate, inputs, T, F, W)
end

function _eforward!(scont::CPUContainer{S}, args) where S<:GenericSynapses
  gs = root(scont)

  # Get output connection
  tgt_conn = first(filter(conn->conn.op==:output, gs.conns))
  tgt_cont = first(filter(arg->arg[2]==tgt_conn.uuid, args))[3]
  tgt_node = root(tgt_cont)

  # FIXME: Use dispatch to get these values
  Tout = tgt_node.state.T
  Fout = tgt_node.state.F
  Iout = tgt_node.state.I

  # Clear output neuron inputs
  #fill!(Iout, 0.0)

  for src_conn in filter(conn->conn.op!=:output, gs.conns)
    src_cont = first(filter(arg->arg[2]==src_conn.uuid, args))[3]
    src_node = root(src_cont)

    # TODO: Use dispatch to get these values
    inputs = src_node.state.F
    shift_frontend!(src_conn.data, inputs)

    # Clear connection outputs
    #fill!(O, 0.0)

    O = calculate_outputs!(src_conn.data, inputs)
    # FIXME: Multiply by tgt_conn.data.outputMask
    Iout .+= O

    learn_weights!(src_conn.data, tgt_conn.data, tgt_node, inputs)
  end
end
