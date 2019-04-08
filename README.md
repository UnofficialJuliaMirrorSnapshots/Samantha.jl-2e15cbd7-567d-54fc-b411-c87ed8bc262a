# Samantha.jl

[![pipeline status](https://gitlab.com/Samantha.ai/Samantha.jl/badges/master/pipeline.svg)](https://gitlab.com/Samantha.ai/Samantha.jl/commits/master)

Spiking neural network engine written in Julia, which is primarily aimed at creating and running human-like AI agents in real-time.

## Goals
* High-performance spiking neural network core  
* Stable real-time operation and interactivity  
* Flexible choice of various algorithms and parameters  
* Persistence of data at the filesystem level via file mmap  
* Acceleration of algorithms via GPUs or other offloading hardware  
* Efficient usage of high-performance network fabrics  

## Installation
Install a supported version of Julia (currently 0.6 or greater) on a supported OS.  
```
Pkg.clone("https://gitlab.com/Samantha.ai/Samantha.jl")
```

## License
Samantha is licensed under the MIT "Expat" license. Please see LICENSE.md for the full license terms.
