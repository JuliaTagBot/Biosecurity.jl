module Biosecurity
# Use the README as the module docs
@doc read(joinpath(dirname(@__DIR__), "README.md"), String) Biosecurity

using ConstructionBase,
      Distributions,
      DynamicGrids,
      DocStringExtensions,
      FieldDefaults,
      FieldMetadata,
      Mixers,
      Reexport

@reexport using Dispersal

import DynamicGrids: applyrule, applyrule!, applyinteraction, applyinteraction!,
       neighbors, neighborhood, setneighbor!, mapsetneighbor!,
       radius, framesize, mask, overflow, cellsize, ruleset,
       currenttime, currenttimestep, starttime, stoptime, timestep, tspan,
       storeframe!, initframes!

import Dispersal: @columns

import ConstructionBase: constructorof

import FieldMetadata: @description, @limits, @flattenable,
                      default, description, limits, flattenable

export DetectionModel, ThresholdDetection, ProbabilisticDetection

export Detection

export NeighborhoodResponse, RegionResponse

export Eradication

export QuarantinedHumanDispersal

export FixedCost, DynamicCost, DynamicThresholdCost

# Documentation templates
@template TYPES =
    """
    $(TYPEDEF)
    $(DOCSTRING)
    """

include("quarantine.jl")
include("detection.jl")
include("response.jl")
include("eradication.jl")
include("costs.jl")
include("outputs.jl")


end # module
