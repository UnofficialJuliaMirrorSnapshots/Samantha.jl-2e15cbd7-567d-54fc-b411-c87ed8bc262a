@testset "Interface Test" begin
  agent = Agent()
  n1 = GenericNeurons(8)
  addnode!(agent, n1; name="N1")
  n2 = GenericNeurons(8)
  addnode!(agent, n2; name="N2")

  # Hooks
  interface = AgentInterface(agent)
  addhook!(interface, "Input", interface["N1"], (:state, :I))
  addhook!(interface, "Output", interface["N2"], (:state, :F))
  delhook!(interface, "Input")
  cO = gethook(interface, "Output")
  O = get(cO)
  @test typeof(O) <: GenericNeurons
  sethook!(interface, "Output", O)
end
