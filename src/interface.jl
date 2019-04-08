export addhook!, delhook!, gethook, sethook

struct AgentInterface
  agent::Agent
  hooks::Dict{String,Tuple{String,NTuple{N,String} where N}}
end
AgentInterface(agent) = AgentInterface(agent, Dict{String,Tuple{String,NTuple{N,String} where N}}())

# Adds a hook to an interface
# TODO: Validate that path exists
function addhook!(interface::AgentInterface, name::String, obj::String, path::Tuple)
  @assert !haskey(interface.hooks, name) "Hook $name already exists"
  interface.hooks[name] = (name, map(param->(param isa Val ? param : Val{param}()), path))
end

# Deletes a hook from an interface
function delhook!(interface::AgentInterface, name::String)
  @assert haskey(interface.hooks, name) "Hook $name does not exist"
  Base.delete!(interface.hooks, name)
end

# Gets the value of an interface hook
# FIXME: Actually lookup the parameter
function gethook(interface::AgentInterface, name::String)
  interface.nodes[interface.hooks[name]]
end

# Sets the value of an interface hook
# FIXME: Actually lookup the parameter
sethook!(interface::AgentInterface, name::String, value) = (interface.hooks[name] = value)
