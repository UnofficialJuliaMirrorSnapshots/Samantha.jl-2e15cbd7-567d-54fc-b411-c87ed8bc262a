### Methods ###

function CerebellumModel(config::Dict)
  numZones = get(config, "numZones", 4)
  szGr = get(config, "szGr", 32)
  szPk = get(config, "szPk", 8)
  szDc = get(config, "szDc", 4)
  szIo = get(config, "szIo", 4)

  agent = Agent()

  # TODO: Split out Granule neurons for sharing purposes
  # TODO: Delays
  for i = 1:numZones
    agent_Zone = Agent()

    # Granule neurons
    addnode!(agent_Zone, GenericNeurons(szGr); name="Gr")

    # Purkinje neurons
    addnode!(agent_Zone, GenericNeurons(szPk); name="Pk")

    # Deep Cerebellar neurons
    addnode!(agent_Zone, GenericNeurons(szDc); name="Dc")

    # Inferior Olive neurons
    addnode!(agent_Zone, GenericNeurons(szIo); name="Io")
    
    # Gc -> Pk
    # TODO: Masking
    # TODO: Increasing individual delays
    addnode!(agent_Zone, GenericSynapses(szGr, szPk); name="Gr_Pk")
    addedge!(agent_Zone, agent_Zone["Gr_Pk"], (
      (agent_Zone["Gr"], :input),
      (agent_Zone["Pk"], :output)
    ))

    # Pk -(Inh)> Dc
    addnode!(agent_Zone, GenericSynapses(szPk, szDc; outputMask=-1); name="Pk_Dc")
    addedge!(agent_Zone, agent["Pk_Dc"], (
      (agent_Zone["Pk"], :input),
      (agent_Zone["Dc"], :output)
    ))

    # Dc -(Inh)> Io
    addnode!(agent_Zone, GenericSynapses(szDc, szIo; outputMask=-1); name="Dc_Io")
    addedge!(agent_Zone, agent["Dc_Io"], (
      (agent_Zone["Dc"], :input),
      (agent_Zone["Io"], :output)
    ))

    # Io -> Dc
    addnode!(agent_Zone, GenericSynapses(szIo, szDc); name="Io_Dc")
    addedge!(agent_Zone, agent["Io_Dc"], (
      (agent_Zone["Io"], :input),
      (agent_Zone["Dc"], :output)
    ))

    # Io -> Io
    addnode!(agent_Zone, GenericSynapses(szIo, szIo); name="Io_Io")
    addedge!(agent_Zone, agent["Io_Io"], (
      (agent_Zone["Io"], :input),
      (agent_Zone["Io"], :output)
    ))

    agent["$i"] = agent_Zone
  end

  return agent
end
