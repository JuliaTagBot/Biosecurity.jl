using Biosecurity, Test

traps =          [1 0 0 0 0;
                  0 0 0 0 0;
                  0 0 0 1 0;
                  0 0 0 0 0;
                  0 0 0 0 0]
regions =        [1 1 2 2 2;
                  1 1 2 2 2;
                  1 1 2 2 2;
                  1 1 2 2 2;
                  1 1 2 2 2]
industry_value = [1e1 1e2 0.0 0.0 0.0;
                  0.0 1e1 0.0 0.0 1e1;
                  0.0 1e1 0.0 1e2 0.0;
                  0.0 0.0 0.0 0.0 1e2;
                  1e2 0.0 0.0 1e1 0.0]

# Grids
detectedgrid = Bool[0 0 0 0 0;
                    0 0 0 0 0;
                    0 0 0 0 0;
                    0 0 0 0 0;
                    0 0 0 0 0]
localgrid =    Bool[0 0 0 0 0;
                    0 0 0 0 0;
                    0 0 0 0 0;
                    0 0 0 0 0;
                    0 0 0 0 0]
regiongrid =   Bool[0 0 0 0 0;
                    0 0 0 0 0;
                    0 0 0 0 0;
                    0 0 0 0 0;
                    0 0 0 0 0]
populationgrid =   [0.0 1.0 0.0 1.0 1.0;
                    0.3 1.0 1.0 0.3 1.0;
                    1.0 1.0 1.0 4.0 0.1;
                    0.0 1.0 0.0 1.5 2.3;
                    1.0 1.0 1.0 2.2 3.0]
costgrid =         [0.0 0.0 0.0 0.0 0.0;
                    0.0 0.0 0.0 0.0 0.0;
                    0.0 0.0 0.0 0.0 0.0;
                    0.0 0.0 0.0 0.0 0.0;
                    0.0 0.0 0.0 0.0 0.0]

init = (population=populationgrid, detected=detectedgrid, loc=localgrid,
        region=regiongrid, cost=costgrid)

# Simple growth model
struct AddOne <: CellRule end
Biosecurity.applyrule(rule::AddOne, data, state, index) = state + one(state)

threshold = 7
# Detection
detection = Detection(
    population=:population,
    detected=:detected,
    sites=traps,
    sitemask=nothing,
    detectionmode=ThresholdDetection(threshold)
)

loc_response = NeighborhoodResponse(detected=:detected, response=:loc)
region_response = RegionResponse(detected=:detected, response=:region, regions=regions)

@testset "Detection" begin

    ruleset = MultiRuleset(
        rulesets=(
            population=Ruleset(AddOne()),
        ),
        interactions=(detection, loc_response, region_response),
        init=init
    )
    output = ArrayOutput(init, 10)
    sim!(output, ruleset; tspan=(1, 10), fps=10);

    @test output[4][:population] ==
        [3.0 4.0 3.0 4.0 4.0
         3.3 4.0 4.0 3.3 4.0
         4.0 4.0 4.0 7.0 3.1
         3.0 4.0 3.0 4.5 5.3
         4.0 4.0 4.0 5.2 6.0]

    @test output[1][:detected] == output[3][:detected] ==
        output[1][:loc] == output[3][:loc] ==
        output[1][:region] == output[3][:region] ==
        [0 0 0 0 0;
         0 0 0 0 0;
         0 0 0 0 0;
         0 0 0 0 0;
         0 0 0 0 0]

    # First response
    @test output[4][:detected] == output[7][:detected] ==
        [0 0 0 0 0;
         0 0 0 0 0;
         0 0 0 1 0;
         0 0 0 0 0;
         0 0 0 0 0]

    # First response
    @test output[4][:loc] == output[7][:loc] ==
        [0 0 0 0 0;
         0 0 1 1 1;
         0 0 1 1 1;
         0 0 1 1 1;
         0 0 0 0 0]

    @test output[4][:region] == output[7][:region] ==
        [0 0 1 1 1
         0 0 1 1 1
         0 0 1 1 1
         0 0 1 1 1
         0 0 1 1 1]

    # First response
    @test output[8][:detected] == output[10][:detected] ==
        [1 0 0 0 0;
         0 0 0 0 0;
         0 0 0 1 0;
         0 0 0 0 0;
         0 0 0 0 0]

    # Second response
    @test output[8][:loc] == output[10][:loc] ==
        [1 1 0 0 0;
         1 1 1 1 1;
         0 0 1 1 1;
         0 0 1 1 1;
         0 0 0 0 0]

    @test output[8][:region] == output[10][:region] ==
        [1 1 1 1 1
         1 1 1 1 1
         1 1 1 1 1
         1 1 1 1 1
         1 1 1 1 1]

end


# Eradication
eradication = Eradication(population=:population, eradicate=:loc, carrying_capacity=1.0)

@testset "Eradication" begin

    # Complete ruleset
    ruleset = MultiRuleset(
        rulesets=(
            population=Ruleset(AddOne()),
        ),
        interactions=(detection, loc_response, region_response, eradication),
        init=init
    )
    output = ArrayOutput(init, 10)
    sim!(output, ruleset; tspan=(1, 10), fps=10);

    @test output[4][:population] ==
        [3.0  4.0  3.0  4.0  4.0
         3.3  4.0  1.0  1.0  1.0
         4.0  4.0  1.0  1.0  1.0
         3.0  4.0  1.0  1.0  1.0
         4.0  4.0  4.0  5.2  6.0]

    @test output[7][:population] ==
        [6.0  7.0  6.0  7.0  7.0
         6.3  7.0  1.0  1.0  1.0
         7.0  7.0  1.0  1.0  1.0
         6.0  7.0  1.0  1.0  1.0
         7.0  7.0  7.0  8.2  9.0]

    @test output[8][:population] ==
        [1.0  1.0  7.0  8.0  8.0
         1.0  1.0  1.0  1.0  1.0
         8.0  8.0  1.0  1.0  1.0
         7.0  8.0  1.0  1.0  1.0
         8.0  8.0  8.0  9.2 10.0]

    @test output[10][:population] ==
        [1.0  1.0  9.0 10.0 10.0
         1.0  1.0  1.0  1.0  1.0
        10.0 10.0  1.0  1.0  1.0
         9.0 10.0  1.0  1.0  1.0
        10.0 10.0 10.0 11.2 12.0]

end

# using DynamicGridsGtk, ColorSchemes, Colors
# zerocolor = RGB24(0.7)
# maskcolor = RGB24(0.0)
# oranges = ColorProcessor(ColorSchemes.Oranges_3, zerocolor, maskcolor)
# blues = ColorProcessor(ColorSchemes.Blues_3, zerocolor, maskcolor)
# jet = ColorProcessor(ColorSchemes.jet, zerocolor, maskcolor)
# viridis = ColorProcessor(ColorSchemes.viridis, zerocolor, maskcolor)
# ocean = ColorProcessor(ColorSchemes.ocean, zerocolor, maskcolor)
# processor = LayoutProcessor([:population :cost nothing; :detected :loc :region],
#                             (oranges, blues, viridis, ocean, jet))
# output = GtkOutput(init; processor=processor, minval=(0, 0, 0, 0, 0), maxval=(10, 1, 1, 1, 2000), store=true)
# sim!(output, ruleset; tspan=(1, 10), fps=2);

@testset "Cost" begin

    # Trap Cost
    quarantine_cost = 10.0
    costpertrap = 1.0
    loss = 0.01
    trapcost = FixedCost(traps, costpertrap)

    ruleset = MultiRuleset(
        rulesets=(
            population=Ruleset(AddOne()),
            cost=Ruleset(trapcost),
        ),
        interactions=(detection, 
                      loc_response, 
                      region_response, 
                      eradication,
                     ),
        init=init
    )
    output = ArrayOutput(init, 10)
    sim!(output, ruleset; tspan=(1, 10), fps=10);

    @test output[10][:cost] == 
        [9.0 0.0 0.0 0.0 0.0
         0.0 0.0 0.0 0.0 0.0
         0.0 0.0 0.0 9.0 0.0
         0.0 0.0 0.0 0.0 0.0
         0.0 0.0 0.0 0.0 0.0]


    # Industry cost
    industrycost = DynamicThresholdCost(
        source=:population,
        cost=:cost,
        sitevalue=industry_value,
        scalar=1.0,
        threshold=2.0,
    )

    ruleset = MultiRuleset(
        rulesets=(
            population=Ruleset(AddOne()),
        ),
        interactions=(
                      industrycost,
                      detection, 
                      loc_response, 
                      region_response, 
                      eradication,
                     ),
        init=init
    )
    output = ArrayOutput(init, 10)
    sim!(output, ruleset; tspan=(1, 10), fps=10);

    @test output[10][:cost] == 
        [  50.0 600.0  0.0   0.0   0.0
           0.0   60.0  0.0   0.0  20.0
           0.0   80.0  0.0 300.0   0.0
           0.0    0.0  0.0   0.0 300.0
         800.0    0.0  0.0  90.0   0.0]


    quarantinecost = DynamicCost(
        source=:region,
        cost=:cost,
        sitevalue=industry_value,
        scalar=1.0
    )
    ruleset = MultiRuleset(
        rulesets=(
            population=Ruleset(AddOne()),
        ),
        interactions=(detection, 
                      loc_response, 
                      region_response, 
                      eradication,
                      quarantinecost,
                     ),
        init=init
    )
    output = ArrayOutput(init, 10)
    sim!(output, ruleset; tspan=(1, 10), fps=10);

    @test output[10][:cost] == 
      [  30.0 300.0 0.0   0.0   0.0
         0.0   30.0 0.0   0.0  70.0
         0.0   30.0 0.0 700.0   0.0
         0.0    0.0 0.0   0.0 700.0
       300.0    0.0 0.0  70.0   0.0]
end


# Visualisation
# using DynamicGridsGtk, ColorSchemes, Colors
# zerocolor = RGB24(0.7)
# maskcolor = RGB24(0.0)
# oranges = ColorProcessor(ColorSchemes.Oranges_3, zerocolor, maskcolor)
# blues = ColorProcessor(ColorSchemes.Blues_3, zerocolor, maskcolor)
# jet = ColorProcessor(ColorSchemes.jet, zerocolor, maskcolor)
# viridis = ColorProcessor(ColorSchemes.viridis, zerocolor, maskcolor)
# ocean = ColorProcessor(ColorSchemes.ocean, zerocolor, maskcolor)
# processor = LayoutProcessor([:population :cost nothing; :detected :loc :region],
#                             (oranges, blues, viridis, ocean, jet))
# output = GtkOutput(init; processor=processor, minval=(0, 0, 0, 0, 0), maxval=(10, 1, 1, 1, 2000), store=true)
# sim!(output, ruleset; tspan=(1, 10), fps=2);
