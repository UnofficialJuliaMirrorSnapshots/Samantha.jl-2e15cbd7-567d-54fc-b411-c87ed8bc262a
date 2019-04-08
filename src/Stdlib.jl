module Stdlib
  #import Base: include
  export include

  function include(lib::String, file::String)
    if file == "*"
      # Load all files from lib
      if ispath(@__DIR__, "stdlib", lib, "includes.jl")
        # Use includes.jl if available
        Base.include(joinpath(@__DIR__, "stdlib", lib, "includes.jl"))
      else
        # If no includes.jl, load in any order
        for f in filter(x->endswith(x,".jl"), readdir(joinpath(@__DIR__, "stdlib", lib)))
          path = joinpath(@__DIR__, "stdlib", lib, f)
          Base.include(path)
        end
      end
    else
      # Load specified file from lib
      path = joinpath(@__DIR__, "stdlib", lib, file)
      @assert ispath(path) "Failed to locate $lib/$file in Stdlib"
      Base.include(path)
    end
  end
  function include_lib(lib::String)
    if lib == "*"
      # TODO: Load all libraries and files
    else
      # TODO: Load all files from specified lib
    end
  end
end
