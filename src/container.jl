### Exports ###

export CPUContainer
export root, transient

### Types ###

# InactiveContainer doesn't do anything, so it doesn't need a transient
mutable struct InactiveContainer{R} <: AbstractContainer
  root::R
end
# CPUContainer doesn't store data anywhere special, so it doesn't need a transient
mutable struct CPUContainer{R} <: AbstractContainer
  root::R
end

### Methods ###

# Gets the root of a container
root(cont::AbstractContainer) = cont.root

# Gets the transient of a container
# TODO: Replace with getfield?
transient(cont::AbstractContainer) = cont.transient
transient(cont::InactiveContainer) = root(cont)
transient(cont::CPUContainer) = root(cont)

==(cont1::CPUContainer, cont2::CPUContainer) =
  root(cont1) == root(cont2)
