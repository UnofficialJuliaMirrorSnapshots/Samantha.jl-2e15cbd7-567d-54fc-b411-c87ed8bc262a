### Methods ###

function ThalamusModel(config::Dict)
  numTR = get(config, "numTR", 8)
  numtRN = get(config, "numtRN", 1)
  szTR = get(config, "szTR", 64)
  sztRN = get(config, "sztRN", 64)

  agent = Agent()

  agent_TR = Agent()
  for i = 1:numTR
    addnode!(agent_TR, GenericNeurons(szTR; b=0.25, d=0.05); name="$i")
  end
  agent_tRN = Agent()
  for i = 1:numtRN
    addnode!(agent_tRN, GenericNeurons(sztRN; a=0.1, d=2); name="$i")
  end
  agent["TR"] = agent_TR
  agent["tRN"] = agent_tRN

  # Reciprocally connect TR and tRN
  for i = 1:numTR
    for j = 1:numtRN
      # TODO: Delays
      # TODO: Masking
      addnode!(agent, GenericSynapses(szTR, sztRN; outputMask=-1); name="TR_$(i)_tRN_$(j)")
      addedge!(agent, agent["TR_$(i)_tRN_$(j)"], (
        (agent["TR"]["$i"], :input),
        (agent["tRN"]["$j"], :output)
      ))
      addnode!(agent, GenericSynapses(sztRN, szTR); name="tRN_$(j)_TR_$(i)")
      addedge!(agent, agent["tRN_$(j)_TR_$(i)"], (
        (agent["tRN"]["$j"], :input),
        (agent["TR"]["$i"], :output)
      ))
    end
  end

  return agent
end
