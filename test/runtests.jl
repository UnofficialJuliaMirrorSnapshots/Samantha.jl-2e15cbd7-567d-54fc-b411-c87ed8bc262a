# Parse arguments, if any
path = "RUNME.jl"
for arg in ARGS
  if ispath(arg)
    path = arg
  else
    error("Unknown argument: $arg")
  end
end

using Samantha
using Random
using Test

if path == "RUNME.jl"
  @info "Running All Tests"
else
  @info "Running Test $path"
end
include(path)
