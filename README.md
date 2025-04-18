# CropGrowthTutorial

## Introduction

This tutorial helps to understand how to use [AquaCrop.jl](https://github.com/gabo-di/AquaCrop.jl)  
calibrating crop parameters to real data. This tutorial is part of [Persefone project](https://persefone-model.eu).
We use data from [RDWD](https://github.com/brry/rdwd) and 
[Thüringer Landesamt für Statistik](https://statistik.thueringen.de/datenbank/TabAnzeige.asp?tabelle=kr000516%7C%7C).

## Installation

This code base is using the [Julia Language](https://julialang.org/) and
[DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/)
to make a reproducible scientific project named
> CropGrowthTutorial

To (locally) reproduce this project, do the following:

0. Download this code base. Notice that raw data are typically not included in the
   git-history and may need to be downloaded independently.
1. Open a Julia console and do:
   ```
   julia> using Pkg
   julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`
   julia> Pkg.activate("path/to/this/project")
   julia> Pkg.instantiate()
   ```

This will install all necessary packages for you to be able to run the scripts and
everything should work out of the box, including correctly finding local paths.

You may notice that most scripts start with the commands:
```julia
using DrWatson
@quickactivate "CropGrowthTutorial"
```
which auto-activate the project and enable local path handling from DrWatson.

## Run Notebooks

In case you have problems runing the notbooks then run
```julia
using IJulia
IJulia.installkernel("Julia CropGrowthTutorial", "--project=$(Base.active_project())")
notebook(;dir=projectdir(), detached=true)
```
then browse to the notebook that you want to run.

## Run Scripts

Inside a julia sesion you can do the following
```
using DrWatson
@quickactivate

include(scriptsdir("script_name.jl")) # change script_name.jl with the actual name of the script you want to run
main() # main() is the entry point to run the code on the script
```

## Data

We are adding the raw data to run the simulations in `data/exp_raw`, 
and the result of the crop calibration on `data/sims`
