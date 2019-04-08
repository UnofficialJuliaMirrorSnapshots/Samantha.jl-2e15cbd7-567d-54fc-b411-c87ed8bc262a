addedge!(srccont::C, dstcont, dst, op, conf) where C<:AbstractContainer =
  addedge!(root(srccont), dstcont, dst, op, conf)
deledge!(srccont::C, dst, op) where C<:AbstractContainer =
  deledge!(root(srccont), dst, op)
deledges!(srccont::C) where C<:AbstractContainer =
  deledges!(root(srccont))

nupdate!(cont::CPUContainer{C}) where C<:AbstractNode = nupdate!(transient(cont))
nupdate!(x::Any) = ()

sync!(cont::C) where C<:AbstractContainer = sync!(cont.root) # TODO: First pull down transient?
sync!(num::N) where N<:Number = ()
sync!(arr::A) where A<:AbstractArray = Mmap.sync!(arr)

mutate!(cont::CPUContainer{C}, args...) where C = mutate!(transient(cont), args...)

defaultvalue(obj, param1, params...) = defaultvalue(obj[param1], params...)
defaultvalue(obj, param::T) where T<:Val = defaultvalue(obj[param])
defaultvalue(x::T) where T<:Number = zero(T)

bounds(obj, param1, params...) = bounds(obj[param1], params...)
bounds(obj, param::T) where T<:Val = bounds(obj[param])
bounds(x::T) where T<:Number = (zero(T), one(T))

Base.size(cont::CPUContainer{C}) where C<:AbstractNode =
  size(root(cont))

Base.getindex(cont::CPUContainer{C}, idx...) where C<:AbstractNode =
  getindex(root(cont), idx...)
