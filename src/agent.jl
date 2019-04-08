export Agent
export sync!, addnode!, delnode!, addedge!, deledge!, deledges!, merge, merge!, barrier
export activate!, deactivate!
export relocate!, store!, sync!, addnode!, delnode!, addedge!, deledge!, merge, merge!, barrier
export run_edges!, run_nodes!, run!

# FIXME: Make immutable if possible
mutable struct Agent
  nodes::Dict{UUID, AbstractContainer}
  edges::Vector{Tuple{UUID, UUID, Symbol}}
end
Agent() = Agent(Dict{UUID,AbstractContainer}(), Tuple{UUID,UUID,Symbol}[])

# Gets/sets a node
getindex(agent::Agent, uuid::UUID) = agent.nodes[uuid]
getindex(agent::Agent, uuid::AbstractString) = agent[UUID(uuid)]
# FIXME: Container stuff
#setindex!(agent::Agent, node, uuid::UUID) = agent.nodes[uuid] = node
#setindex!(agent::Agent, node, uuid::AbstractString) = agent[UUID(uuid)] = node

# Adds a node
function addnode!(agent::Agent, node::AbstractNode)
  id = uuid4()
  agent.nodes[id] = CPUContainer(node)
  return id
end

# Deletes a node
# TODO: Delete associated edges
function delnode!(agent::Agent, id::UUID)
  node = agent.nodes[id]
  Base.delete!(agent.nodes, id)
end

# Adds an edge connection from a source node to a target node with a specified operation
function addedge!(agent::Agent, src::UUID, dst::UUID, op::Symbol, conf=NamedTuple())
  addedge!(agent.nodes[src], agent.nodes[dst], dst, op, conf)
  push!(agent.edges, (src, dst, op))
end
function addedge!(agent::Agent, src::UUID, pairs::Tuple)
  for pair in pairs
    conf = length(pair) == 3 ? pair[3] : NamedTuple()
    addedge!(agent, src, pair[2], pair[1], conf)
  end
end

# Deletes an edge
function deledge!(agent::Agent, src::UUID, dst::UUID, op::Symbol)
  edges = findall(edge->(edge[1]==src&&edge[2]==dst&&edge[3]==op), agent.edges)
  @assert length(edges) != 0 "No such edge found with src: $src, dst: $dst, op: $op"
  @assert length(edges) < 2 "Multiple matching edges returned"
  deledge!(agent.nodes[src], dst, op)
  deleteat!(agent.edges, edges[1])
end
deledge!(agent::Agent, edge::Tuple{UUID,UUID,Symbol}) =
  deledge!(agent, edge...)

# Deletes all edges originating from a node
function deledges!(agent::Agent, src::UUID)
  edges = findall(edge->(edge[1]==src), agent.edges)
  deledges!(agent.nodes[src])
  # TODO: Add assertion that this works as intended
  deleteat!.(Ref(agent.edges), reverse(edges))
end

# Returns the union of two agents
function merge(agent1::Agent, agent2::Agent)
  agent3 = Agent()
  agent3.nodes = Base.merge(agent1.nodes, agent2.nodes)
  agent3.edges = vcat(agent1.edges, agent2.edges)
  return agent3
end

# Merges agent2 into agent1
function merge!(agent1::Agent, agent2::Agent)
  Base.merge!(agent1.nodes, agent2.nodes)
  agent1.edges = vcat(agent1.edges, agent2.edges)
  return agent1
end

# Sets a barrier on all agent nodes
function barrier(agent::Agent)
  for node in values(agent.nodes)
    barrier(node)
  end
end

# Re-initializes transient data in an agent (such as learned weights or temporary values)
function reinit!(agent::Agent)
  for node in values(agent.nodes)
    reinit!(root(node))
  end
end

# Prints a text overview of the agent
# TODO: Use colors if enabled
# TODO: Optionally elaborate nodes, edges, groups?
function Base.show(io::IO, agent::Agent)
  print(io, "Agent($(length(agent.nodes)) nodes, $(length(agent.edges)) edges)")
end

# Runs all nodes for one iteration
function run_nodes!(agent::Agent)
  nodes = collect(values(agent.nodes))
  for node in nodes
    nupdate!(node)
  end
end

# Runs all edge-connected nodes for one iteration
function run_edges!(agent::Agent)
  # Construct edge sets
  # TODO: Support multiple nodes with the same op
  edges = Dict{UUID, Vector{Tuple{Symbol,UUID,AbstractContainer}}}()
  for edgeObj in agent.edges
    name = edgeObj[1]
    entry = (edgeObj[3], edgeObj[2], agent.nodes[edgeObj[2]])
    if haskey(edges, name)
      push!(edges[name], entry)
    else
      edges[name] = Tuple{Symbol,UUID,AbstractContainer}[entry]
    end
  end
  
  # Run edges
  for edgeName in keys(edges)
    eforward!(agent.nodes[edgeName], edges[edgeName])
  end
end

# Runs agent for one iteration
function run!(agent::Agent)
  # Forward pass on each node
  run_nodes!(agent)

  # Forward pass on edge-connected nodes
  run_edges!(agent)
end

==(agent1::Agent, agent2::Agent) =
  (agent1.nodes == agent2.nodes) && (agent1.edges == agent2.edges)
