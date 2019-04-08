@testset "Core Tests" begin
  include("core-test.jl")
  @test_broken "Interface Tests"

  @test_skip "GenericNeurons"
  @test_skip "GenericSynapses"
  @test_skip "ConvNeurons"
  @test_skip "ConvSynapses"
end
