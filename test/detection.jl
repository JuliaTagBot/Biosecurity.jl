using Biosecurity, Test

sites = [1 0 0 0 0;
         0 0 0 0 0;
         0 0 0 1 0;
         0 0 0 0 0;
         0 0 0 0 0]

sitemask= BitArray([1 1 1 1 1;
                    1 1 1 1 1;
                    1 1 1 1 1;
                    1 1 1 1 1;
                    1 1 1 1 1])

local_response = [0 0 0 0 0;
                  0 0 0 0 0;
                  0 0 0 0 0;
                  0 0 0 0 0;
                  0 0 0 0 0]

juristiction_response = [0 0 0 0 0;
                         0 0 0 0 0;
                         0 0 0 0 0;
                         0 0 0 0 0;
                         0 0 0 0 0]

pop = [0.0 1.0 0.0 1.0 1.0;
       0.3 1.0 1.0 0.3 1.0;
       1.0 1.0 1.0 4.0 0.1;
       0.0 1.0 0.0 1.5 2.3;
       1.0 1.0 1.0 2.2 3.0]

init = (pop=pop, local_response=local_response, juristiction_response=juristiction_response)

struct AddOne <: CellRule end
DynamicGrids.applyrule(rule::AddOne, data, state, index) = state + one(state)


detection = Detection(population=:pop, 
                      local_response=:local,
                      juristiction_response=:quarantine,
                      sites=sites,
                      sitemask=sitemask,
                      juristictions=sitemask,
                      detectionmode=ThresholdDetection(7),
                      neighborhood=RadialNeighborhood{1}())


ruleset = MultiRuleset(rulesets=(pop=Ruleset(AddOne()), quarantine=Ruleset()),
                    interactions=(detection,),
                    init=init)

output = ArrayOutput(init, 10)
# using DynamicGridsGtk
# processor=DynamicGrids.ThreeColor(colors=(DynamicGrids.Green(), DynamicGrids.Red()))
# output = GtkOutput(init; processor=processor, minval=(0, 0), maxval=(10, 1), store=true)
# output.running = false
sim!(output, ruleset; tspan=(1, 10), fps=3);

@test output[1][:quarantine] == output[3][:quarantine] == [0 0 0 0 0;
                                                           0 0 0 0 0;
                                                           0 0 0 0 0;
                                                           0 0 0 0 0;
                                                           0 0 0 0 0]
# First quarantine
@test output[4][:quarantine] == output[7][:quarantine] == [0 0 0 0 0;
                                                           0 0 1 1 1;
                                                           0 0 1 1 1;
                                                           0 0 1 1 1;
                                                           0 0 0 0 0]
# Second quarantine
@test output[8][:quarantine] == output[10][:quarantine] == [1 1 0 0 0;
                                                            1 1 1 1 1;
                                                            0 0 1 1 1;
                                                            0 0 1 1 1;
                                                            0 0 0 0 0]
