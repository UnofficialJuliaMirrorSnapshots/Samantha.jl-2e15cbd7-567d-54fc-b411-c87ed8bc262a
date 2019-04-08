using VT100

@nodegen mutable struct VT100Node <: AbstractNode
  screen::ScreenEmulator
end
VT100Node(w, h) = VT100Node(ScreenEmulator(w, h))
