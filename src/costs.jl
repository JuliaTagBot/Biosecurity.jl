
@description @limits @flattenable struct FixedCost{S,C} <: CellRule
    # Field  | Flatten | Limits          | Description
    sites::S | false   | _               | "Array cell costs"
    cost::C  | true    | (0.0, 100000.0) | "Cost of traps per timestep"
end

@inline applyrule(rule::FixedCost, data, state, index) =
    interaction.trap_sites[index...] * interaction.trap_cost

"""
Interaction that adds costs based on a fixed value layer and another dynamic grid.
"""
@description @limits @flattenable struct DynamicCost{K,V,L} <: CellInteraction{K}
    # Field  | Flatten | Limits      Description
    value::V | false   | _          | "Matrix of value for each cell per timestep"
    loss::L  | true    | (0.0, 1.0) | "Proportion of industry value lost per timestep"
end
DynamicCost(; cost=:cost, population=:population, value, loss) =
    DynamicCost{(cost,population),typeof(value),typeof(loss)}(value, loss)

@inline applyinteraction(interaction::DynamicCost, data, (cost, population), index) =
    cost + interaction.value[index...] * interaction.loss, population


@description @limits @flattenable struct QuarantineCost{K,Q,J} <: PartialInteraction{K}
    # Field                     | Flatten | Limits          | Description
    cost::Q                     | true    | (0.0, 100000.0) | "Cost of quarantine on industry"
    responsible_juristiction::J | false   | _               | "Juristiction to sum costs for"
end
QuarantineCost(; quarantine=:quarantine,
     cost=:cost,
     population=:population,
     juristiction=nothing,
     quarantine_cost=0.0,
     responsible_juristiction=nothing
    ) = begin
    if nothing in (juristiction, responsible_juristiction) && !(juristiction === responsible_juristiction)
        throw(ArgumentError("juristiction ($juristiction) and responsible_juristiction ($responsible_juristiction) must both have values or both be `nothing`"))
    end
    keys = isnothing(juristiction) ? (quarantine, cost) : (quarantine, cost, juristiction)
    QuarantineCost{keys}(quarantine_cost, responsible_juristiction)
end

@inline applyinteraction!(interaction::QuarantineCost, data, state, index) = begin
    COST, QUARANTINE = 1, 2
    cost, quarantine = state
    # j = interaction.responsible_juristiction
    data[COST][index...] = cost + quarantine * interaction.quarantine_cost
end
