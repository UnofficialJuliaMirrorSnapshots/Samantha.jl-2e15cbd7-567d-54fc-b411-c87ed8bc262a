#= Architecture

Core I/O
  Vital inputs and outputs for various layers
  These include reward signals, sleep/wake signals, system status signals, etc.
Main I/O
  The main inputs and outputs to the system
Gating
  Gates the connections between Main I/O and its target layers
  Gated by the Reinforcement layers
  Bistable activating, and maintains open state when communicating with target layers
  Gain-controls its activity based on activity of relays and target layers
Reinforcement
  Controls the activity of the Gating layers
  Determines its gating policy based on external and internal rewards signals, and whole-system state
Working Memory
  Stores small amounts of information in a stable manner on a short-term basis
  Storage and retrieval policy determined by associated Gating layers
Long Term Memory
  Stores high-level details and relations between them on a long-term basis
  Storage and retrieval policy determined by associated Gating layers
  High sparsity layer allows large information densities
  During storage, spatially- and temporally-close activations become bound together
  During retrieval, previously-bound fragments activate each other
  Retrieval is additionally assisted by the source layers providing reciprocal feedback based
    on newly-retrieved fragments, which allows "walking" along memories in a semi-guided manner
# TODO: Attention/Alerting?
# TODO: General Novelty?
# TODO: CPGs
# TODO: Model/Simulation?
# TODO: Error/Conflict Detection?
# TODO: Control/Monitoring

=#

### Methods ###

function BrainModel(config::Dict)
  _config = deepcopy(config)

  numCol = get!(_config, "numCol", 4)
  numTR = get!(_config, "numTR", numCol)
  szTR = get!(_config, "szTR", 64)
  sztRN = get!(_config, "sztRN", 32)
  szL23e = get!(_config, "szL23e", 32)
  szL4e = get!(_config, "szL4e", 32)
  szL5e = get!(_config, "szL5e", 32)
  szL6e = get!(_config, "szL6e", 32)

  numLanes = get!(_config, "numLanes", 4)
  szUS = get!(_config, "szUS", 8)
  szCS = get!(_config, "szCS", 8)
  szDA = get!(_config, "szDA", 8)
  szPV = get!(_config, "szPV", 8)
  szLV = get!(_config, "szLV", 8)

  numZones = get!(_config, "numZones", 4)
  szGr = get!(_config, "szGr", 32)
  szPk = get!(_config, "szPk", 8)
  szDc = get!(_config, "szDc", 4)
  szIo = get!(_config, "szIo", 4)

  agent = Agent()

  agent["Thalamus"] = ThalamusModel(_config)
  agent["Cortex"] = CortexModel(_config)
  agent["PVLV"] = PVLVModel(_config)
  agent["Cerebellum"] = CerebellumModel(_config)
  agent["Hippocampus"] = HippocampusModel(_config)
  agent["WM"] = WMModel(_config)

  # TODO: Connect inputs to thalamus[TR]
  # TODO: Connect thalamus[TR] to outputs

  # TODO: Connect inputs, cortex[L5] to cerebellum[Gr], cerebellum[Dc]
  # TODO: Connect cerebellum[Dc] to thalamus[TR], outputs

  # Connect thalamus[TR] to cortex[L4e]. cortex[L5e]
  # FIXME: MNE
  for col in keys(agent["Thalamus"]["TR"])
    addedge!(agent, GenericSynapses(szTR, szL4e), agent["Thalamus"]["TR"][col], agent["Cortex"][col]["L4e"]; name="Thalamus_TR_$(col)_Cortex_$(col)_L4e")
    addedge!(agent, GenericSynapses(szTR, szL5e), agent["Thalamus"]["TR"][col], agent["Cortex"][col]["L5e"]; name="Thalamus_TR_$(col)_Cortex_$(col)_L5e")
  end

  # Connect cortex[L6e] to thalamus[TR], thalamus[tRN]
  # FIXME: MNE
  for col in keys(agent["Thalamus"]["TR"])
    addedge!(agent, GenericSynapses(szL6e, szTR), agent["Cortex"][col]["L6e"], agent["Thalamus"]["TR"][col]; name="Cortex_$(col)_L6e_Thalamus_TR_$(col)")
    for trn in keys(agent["Thalamus"]["tRN"])
      addedge!(agent, GenericSynapses(szL6e, sztRN), agent["Cortex"][col]["L6e"], agent["Thalamus"]["tRN"][trn]; name="Cortex_$(col)_L6e_Thalamus_tRN_$(trn)")
    end
  end

  # TODO: Connect lower cortex[L5e] to upper thalamus[TR]
  # TODO: Connect inputs[US] to pvlv[US]
  # TODO: Connect cortex[L5e] to pvlv[CS]
  # TODO: Connect pvlv[???] to thalamus[TR], thalamus[tRN]

  # TODO: Connect cortex[L5e] to hippocampus[ECe]

  return agent
end
