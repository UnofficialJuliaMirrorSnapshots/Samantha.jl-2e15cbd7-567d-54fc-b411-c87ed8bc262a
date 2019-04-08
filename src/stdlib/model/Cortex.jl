### Methods ###

function CortexModel(config::Dict)
  numCol = get(config, "numCol", 4)
  szL23e = get(config, "szL23e", 8)
  szL4e = get(config, "szL4e", 8)
  szL5e = get(config, "szL5e", 8)
  szL6e = get(config, "szL6e", 8)

  agent = Agent()

  # Create neurons
  for c = 1:numCol
    agent_Col = Agent()

    # Layer 2/3
    addnode!(agent_Col, GenericNeurons(szL23e); name="L23e")

    # Layer 4
    addnode!(agent_Col, GenericNeurons(szL4e); name="L4e")

    # Layer 5
    addnode!(agent_Col, GenericNeurons(szL5e); name="L5e")

    # Layer 6
    addnode!(agent_Col, GenericNeurons(szL6e); name="L6e")

    agent["$c"] = agent_Col
  end

  # Connect synapses
  for c = 1:numCol
    ## Intra-column intra-layer synapses

    # L4e -> L4e
    addnode!(agent, GenericSynapses(szL4e, szL4e); name="L4e_$(c)_L4e_$(c)")
    addedge!(agent, agent["L4e_$(c)_L4e_$(c)"], (
      (agent["$c"]["L4e"], :input),
      (agent["$c"]["L4e"], :output)
    ))

    ## Intra-column inter-layer synapses

    # L4e -> L23e
    addnode!(agent, GenericSynapses(szL4e, szL23e); name="L4e_$(c)_L23e_$(c)")
    addedge!(agent, agent["L4e_$(c)_L23e_$(c)"], (
      (agent["$c"]["L4e"], :input),
      (agent["$c"]["L23e"], :output)
    ))
    
    # L23e -> L5e
    addnode!(agent, GenericSynapses(szL23e, szL5e); name="L23e_$(c)_L5e_$(c)")
    addedge!(agent, agent["L23e_$(c)_L5e_$(c)"], (
      (agent["$c"]["L23e"], :input),
      (agent["$c"]["L5e"], :output)
    ))

    # L4e -> L6e
    addnode!(agent, GenericSynapses(szL4e, szL6e); name="L4e_$(c)_L6e_$(c)")
    addedge!(agent, agent["L4e_$(c)_L6e_$(c)"], (
      (agent["$c"]["L4e"], :input),
      (agent["$c"]["L6e"], :output)
    ))

    ## Inter-column synapses
    for d = 1:numCol
      # TODO
    end
  end

  return agent
end
