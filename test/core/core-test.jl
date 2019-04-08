@testset "Core Test" begin
  agent = Agent()

  # Layer
  l1 = addnode!(agent, GenericLayer(8))
  @test length(agent.nodes) == 1
  l2 = addnode!(agent, GenericLayer(8))
  addedge!(agent, l2, (
    (:input, l1),
  ))
  @test length(agent.edges) == 1
  run!(agent)

  lt = addnode!(agent, GenericLayer(8))
  addedge!(agent, lt, (
    (:input, l1),
  ))
  deledge!(agent, lt, l1, :input)
  @test length(agent.edges) == 1
  delnode!(agent, lt)
  @test length(agent.nodes) == 2

  # Deledges!
  lt = addnode!(agent, GenericLayer(8))
  addedge!(agent, lt, (
    (:input, l1),
  ))
  deledges!(agent, lt)
  @test length(root(agent.nodes[lt]).synapses.conns) == 0

  # PatchClamp
  p1 = addnode!(agent, PatchClamp(Bool, 8))
  p2 = addnode!(agent, PatchClamp(8))
  run!(agent)

  # Layer and PatchClamp edges
  addedge!(agent, l1, (
    (:input, p1),
  ))
  addedge!(agent, p2, (
    (:input, l2),
  ))
  run!(agent)

  # RewardModulator
  p3 = addnode!(agent, PatchClamp(Bool, 8))
  addedge!(agent, l2, (
    (:input, p3, (modulator=RewardModulator(),)),
  ))
  run!(agent)

  # Merge
  agent2 = Agent()
  l3 = addnode!(agent2, GenericLayer(16))
  merge!(agent, agent2)
  addedge!(agent, l3, (
    (:input, l2),
  ))
  run!(agent)

  # Clear
  reinit!(agent)

  # Deepcopy
  agent3 = deepcopy(agent)
  run!(agent3)

  # Size
  for (idx, node) in agent.nodes
    @test size(root(node)) != nothing
  end
end
