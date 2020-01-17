using Biosecurity, Test

sites = [1 0 0 0 0;
         0 0 0 0 0;
         0 0 0 1 0;
         0 0 0 0 0;
         0 0 0 0 0]
juristictions = [1 1 2 2 2;
                 1 1 2 2 2;
                 1 1 2 2 2;
                 1 1 2 2 2;
                 1 1 2 2 2]
localgrid = Bool[0 0 0 0 0;
                 0 0 0 0 0;
                 0 0 0 0 0;
                 0 0 0 0 0;
                 0 0 0 0 0]
juristictiongrid = Bool[0 0 0 0 0;
                        0 0 0 0 0;
                        0 0 0 0 0;
                        0 0 0 0 0;
                        0 0 0 0 0]
populationgrid = [0.0 1.0 0.0 1.0 1.0;
                  0.3 1.0 1.0 0.3 1.0;
                  1.0 1.0 1.0 4.0 0.1;
                  0.0 1.0 0.0 1.5 2.3;
                  1.0 1.0 1.0 2.2 3.0]
industry_value = [0.0 1e4 0.0 0.0 0.0;
                  0.0 0.0 0.0 0.0 0.0;
                  0.0 0.0 0.0 1e4 0.0;
                  0.0 0.0 0.0 0.0 0.0;
                  1e4 0.0 0.0 0.0 0.0]
costgrid = [0.0 0.0 0.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0;
            0.0 0.0 0.0 0.0 0.0]

init = (population=populationgrid, local_response=localgrid, juristiction_response=juristictiongrid, cost=costgrid)

# Simple growth model
struct AddOne <: CellRule end
Biosecurity.applyrule(rule::AddOne, data, state, index) = state + one(state)

# Detection
detection = Detection(population=:population,
                      local_response=:local_response,
                      juristiction_response=:juristiction_response,
                      sites=sites,
                      sitemask=nothing,
                      juristictions=juristictions,
                      detectionmode=ThresholdDetection(7),
                      neighborhood=RadialNeighborhood{1}())

# Eradication
eradication = Eradication(; carrying_capacity=1.0)

# Cost
quarantine_cost = 100.0
trap_cost = 1.0
industry_loss = 0.01
cost = Cost(quarantine=:local_response, cost=:cost, population=:population,
             quarantine_cost=quarantine_cost,
             trap_sites=sites,
             trap_cost=trap_cost,
             industry_value=industry_value,
             industry_loss=industry_loss,
            )

# Complete ruleset
ruleset = MultiRuleset(rulesets=(population=Ruleset(AddOne()),
                                 local_response=Ruleset(),
                                 juristiction_response=Ruleset(),
                                 cost=Ruleset()),
                       interactions=(detection, eradication, cost),
                       init=init)

output = ArrayOutput(init, 10)
# output = Biosecurity.CostOutput(20)

# using DynamicGridsGtk, ColorSchemes, Colors
# # processor = ThreeColorProcessor(colors=(DynamicGrids.Green(), DynamicGrids.Red(), DynamicGrids.Blue()))
# zerocolor = RGB24(0.7)
# maskcolor = RGB24(0.0)
# oranges = ColorProcessor(ColorSchemes.Oranges_3, zerocolor, maskcolor)
# blues = ColorProcessor(ColorSchemes.Blues_3, zerocolor, maskcolor)
# jet = ColorProcessor(ColorSchemes.jet, zerocolor, maskcolor)
# viridis = ColorProcessor(ColorSchemes.viridis, zerocolor, maskcolor)
# processor = LayoutProcessor([:population :local_response; :juristiction_response :cost],
#                             (oranges, blues, viridis, jet))
# output = GtkOutput(init; processor=processor, minval=(0, 0, 0, 0), maxval=(10, 1, 1, 2000), store=true)

sim!(output, ruleset; tspan=(1, 10), fps=10);

@testset "Detection" begin
    @test output[1][:local_response] == output[3][:local_response] ==
        output[1][:juristiction_response] == output[3][:juristiction_response] ==
        [0 0 0 0 0;
         0 0 0 0 0;
         0 0 0 0 0;
         0 0 0 0 0;
         0 0 0 0 0]

    # First response
    @test output[4][:local_response] == output[7][:local_response] ==
        [0 0 0 0 0;
         0 0 1 1 1;
         0 0 1 1 1;
         0 0 1 1 1;
         0 0 0 0 0]

    @test output[4][:juristiction_response] == output[7][:juristiction_response] ==
        [0 0 1 1 1
         0 0 1 1 1
         0 0 1 1 1
         0 0 1 1 1
         0 0 1 1 1]

    # Second response
    @test output[8][:local_response] == output[10][:local_response] ==
        [1 1 0 0 0;
         1 1 1 1 1;
         0 0 1 1 1;
         0 0 1 1 1;
         0 0 0 0 0]

    @test output[8][:juristiction_response] == output[10][:juristiction_response] ==
        [1 1 1 1 1
         1 1 1 1 1
         1 1 1 1 1
         1 1 1 1 1
         1 1 1 1 1]
end

@testset "Eradication" begin
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
