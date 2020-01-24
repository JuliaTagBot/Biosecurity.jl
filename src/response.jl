@description @limits @flattenable struct NeighborhoodResponse{Keys,N} <: PartialNeighborhoodInteraction{Keys}
    # Field          | Flatten | Limits       | Description
    neighborhood::N  | false   | _            | "Response neighborhood. Any `Neighborhood` from DynamicGrids.jl"
end
NeighborhoodResponse(; detected=:detected, response=:response, neighborhood=RadialNeighborhood{1}()) =
    NeighborhoodResponse{(detected, response), typeof(neighborhood)}(neighborhood)

@inline applyinteraction!(rule::NeighborhoodResponse, data::MultiSimData, (detected, response), index) = begin
    DETECTED, RESPONSE = 1, 2
    !detected && return # Exit if not detected
    response != 0 && return # Exit if already responded
    mapsetneighbor!(data[RESPONSE], neighborhood(rule), rule, response, index)
    data[RESPONSE][index...] = true
end

# Set neighborhood cells to `true`
@inline setneighbor!(data, hood, rule::NeighborhoodResponse, state, hood_index, dest_index) =
    return data[dest_index...] = true

"""
RegionResponse{Keys,R}

Respond to change
"""
@description @flattenable struct RegionResponse{Keys,R} <: PartialInteraction{Keys}
    # Field    | Flatten | Limits | Description
    regions::R | false   | "Matrix of cells numbered by region"
end
RegionResponse(; detected=:detected, response=:response, regions) =
    RegionResponse{(detected, response)}(regions)

@inline applyinteraction!(rule::RegionResponse, data::MultiSimData, (detected, response), index) = begin
    DETECTED, RESPONSE = 1, 2
    detected && response == 0 || return # Exit if not detected or already responded
    sze = size(rule.regions)
    regionid = rule.regions[index...]
    # Set response to true at indices in the region
    for j in 1:sze[2], i in 1:sze[1]
        if rule.regions[i, j] == regionid
            data[RESPONSE][i, j] = true
        end
    end
    return
end
