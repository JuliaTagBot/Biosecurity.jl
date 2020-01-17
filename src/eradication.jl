@description @limits @flattenable struct Eradication{K,C} <: PartialInteraction{K}
    # Field                | Flatten | Limits     | Description
    carrying_capacity::C   | true    | (0.0, 1e8) | ""
    Eradication{K,C}(carrying_capacity::C) where {K,C} =
        new{K,C}(carrying_capacity)
    Eradication{K}(carrying_capacity::C) where {K,C} =
        new{K,C}(carrying_capacity)
end
Eradication(; population=:population,
            local_response=:local_response,
            carrying_capacity=1e5) =
    Eradication{(population, local_response)}(carrying_capacity)

@inline applyinteraction!(interaction::Eradication{Key}, data,
                          (population, local_response), index) where Key = begin
    POPULATION, LOCAL_QUARANTINE = 1, 2
    if local_response
        data[POPULATION][index...] = 
            min(data[POPULATION][index...], interaction.carrying_capacity)
    end
end
