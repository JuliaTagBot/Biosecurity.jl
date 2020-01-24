
"""
A rule that simply increases
"""
@description @limits @flattenable struct FixedCost{S,C} <: CellRule
    # Field   | Flatten | Limits          | Description
    sites::S  | false   | _               | "Array of site costs"
    scalar::C | true    | (0.0, 100000.0) | "Scalar relating cost of traps to the timestep"
end

@inline applyrule(rule::FixedCost, data, state, index) =
    state + sitevalue(rule.sites, index) * rule.scalar

"""
Interaction that adds cost based on the cell value where another grid crosses a threshold.

We include a scalar so that layers such as anual costs can be converted to monthly costs.
"""
@description @limits @flattenable struct DynamicThresholdCost{K,Si,Sc,T} <: PartialInteraction{K}
    # Field       | Flatten | Limits     |  Description
    sitevalue::Si | false   | _          | "Number or Matrix of cost for each site per timestep"
    scalar::Sc    | true    | (0.0, 1.0) | "Maps the sites array to a cost per timestep"
    treshold::T   | true    | (0.0, 1e3) | "Threshold over which costs are induced"
end
DynamicThresholdCost(; source=:source, cost=:cost, sitevalue=1.0, scalar=1.0, threshold=0.0) =
    DynamicThresholdCost{(source,cost),typeof.((sitevalue,scalar,threshold))...
                        }(sitevalue, scalar, threshold)

@inline applyinteraction!(rule::DynamicThresholdCost, data, (source, cost), index) = begin
    SOURCE, COST = 1, 2
    if source > rule.treshold
        data[COST][index...] = cost + sitevalue(rule, index) * rule.scalar
    end
    return
end

sitevalue(rule::Rule, index) = sitevalue(rule.sitevalue, index)
sitevalue(sites::AbstractArray, index) = sites[index...]
sitevalue(sites::Number, index) = sites


"""
Interaction that adds cost scaled to the value of another grid.
"""
@description @limits @flattenable struct DynamicCost{K,Si,Sc} <: PartialInteraction{K}
    # Field       | Flatten | Limits     | Description
    sitevalue::Si | false   | _          | "Number or Matrix of cost for each site per timestep"
    scalar::Sc    | true    | (0.0, 1.0) | "Scalar that maps grid value to a cost"
end
DynamicCost(; source=:source, cost=:cost, sitevalue, scalar) =
    DynamicCost{(source,cost),typeof(sitevalue),typeof(scalar)}(sitevalue, scalar)

@inline applyinteraction!(rule::DynamicCost, data, (source, cost), index) = begin
    SOURCE, COST = 1, 2
    data[COST][index...] = cost + source * rule.scalar * sitevalue(rule, index)
    return
end
