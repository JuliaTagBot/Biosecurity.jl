"""
An Interaction
"""
@description @limits @flattenable struct Eradication{K,C} <: PartialInteraction{K}
    # Field                | Flatten | Limits     | Description
    carrying_capacity::C   | true    | (0.0, 1e8) | ""
end
Eradication{K}(carrying_capacity::C) where {K,C} = Eradication{K,C}(carrying_capacity)
Eradication(; population=:population, eradicate=:eradicate, carrying_capacity=1e5) =
    Eradication{(population, eradicate)}(carrying_capacity)

@inline applyinteraction!(interaction::Eradication, data, (population, eradicate), index) = begin
    POPULATION, ERADICATE = 1, 2
    if eradicate
        data[POPULATION][index...] = 
            min(data[POPULATION][index...], interaction.carrying_capacity)
    end
end
