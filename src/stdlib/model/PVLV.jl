### Methods ###

function PVLVModel(config::Dict)
  numLanes = get(config, "numLanes", 4)
  szUS = get(config, "szUS", 8)
  szCS = get(config, "szCS", 8)
  szDA = get(config, "szDA", 8)
  szPV = get(config, "szPV", 8)
  szLV = get(config, "szLV", 8)

  agent = Agent()

  # TODO: Pull out US and DA
  for i = 1:numLanes
    agent_Lane = Agent()

    US = GenericNeurons(szUS)
    lUS = addnode!(agent_Lane, US; name="US")
    CS = GenericNeurons(szCS)
    lCS = addnode!(agent_Lane, CS; name="CS")
    DA = GenericNeurons(szDA) # TODO: Use profile with spontaneous activity
    lDA = addnode!(agent_Lane, DA; name="DA")
    PVE = GenericNeurons(szPV)
    lPVE = addnode!(agent_Lane, PVE; name="PVE")
    PVI = GenericNeurons(szPV)
    lPVI = addnode!(agent_Lane, PVI; name="PVI")
    LVE = GenericNeurons(szLV)
    lLVE = addnode!(agent_Lane, LVE; name="LVE")
    LVI = GenericNeurons(szLV)
    lLVI = addnode!(agent_Lane, LVI; name="LVI")

    # TODO: Add RL connections
    # FIXME: MNE
    addnode!(agent_Lane, GenericSynapses(szUS, szPV); name="US_PVE")
    addedge!(agent_Lane, agent_Lane["US_PVE"], lUS, lPVE)
    addnode!(agent_Lane, GenericSynapses(szUS, szPV); name="US_PVI")
    addedge!(agent_Lane, agent_Lane["US_PVE"], lUS, lPVI)
    addnode!(agent_Lane, GenericSynapses(szUS, szLV); name="US_LVE")
    addedge!(agent_Lane, agent_Lane["US_PVE"], lUS, lLVE)
    addnode!(agent_Lane, GenericSynapses(szCS, szLV); name="CS_LVE")
    addedge!(agent_Lane, agent_Lane["CS_LVE"], lCS, lLVE)
    addnode!(agent_Lane, GenericSynapses(szCS, szLV); name="CS_LVI")
    addedge!(agent_Lane, agent_Lane["CS_LVI"], lCS, lLVI)
    addnode!(agent_Lane, GenericSynapses(szPV, szDA); name="PVE_DA")
    addedge!(agent_Lane, agent_Lane["PVE_DA"], lPVE, lDA)
    addnode!(agent_Lane, GenericSynapses(szPV, szDA; outputMask = -1); name="PVI_DA")
    addedge!(agent_Lane, agent_Lane[], l, l)
    addnode!(agent_Lane, GenericSynapses(szLV, szDA); name="LVE_DA")
    addedge!(agent_Lane, agent_Lane[], l, l)
    addnode!(agent_Lane, GenericSynapses(szLV, szDA; outputMask = -1); name="LVI_DA")
    addedge!(agent_Lane, agent_Lane[], l, l)

    agent["$i"] = agent_Lane
  end

  return agent
end
