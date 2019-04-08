module Samantha

using Parameters
using OnlineStats
using Random
import Base: ==, hash
import UUIDs: UUID, uuid4

# Core files
include("imports-exports.jl")
include("abstracts.jl")
include("util.jl")
include("container.jl")
include("defaults.jl")
include("neurons/neurons.jl")
include("synapses/synapses.jl")
include("layer.jl")
include("patchclamp.jl")
include("agent.jl")
include("interface.jl")

# Standard Library
# TODO: include("Stdlib.jl")

# External Optional Dependencies
# TODO: include("external/External.jl")

end
