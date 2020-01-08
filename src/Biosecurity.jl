module Biosecurity
# Use the README as the module docs
@doc read(joinpath(dirname(@__DIR__), "README.md"), String) Biosecurity

using ConstructionBase,
      Distributions,
      DocStringExtensions,
      FieldDefaults,
      FieldMetadata,
      Mixers,
      Reexport

@reexport using Dispersal

import DynamicGrids: applyrule, applyrule!, applyinteraction, applyinteraction!,
       neighbors, neighborhood, setneighbor!, mapreduceneighbors,
       radius, framesize, mask, overflow, cellsize, ruleset,
       currenttime, currenttimestep, starttime, stoptime, timestep, tspan

import Dispersal: @columns 

import ConstructionBase: constructorof

import FieldMetadata: @description, @limits, @flattenable,
                      default, description, limits, flattenable

export DetectionModel, ThresholdDetection

export Detection, QuarantinedHumanDispersal, Cost

# Documentation templates
@template TYPES =
    """
    $(TYPEDEF)
    $(DOCSTRING)
    """

include("quarantine.jl")
include("detection.jl")
include("costs.jl")


end # module
