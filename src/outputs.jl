"""
An output that calculates the total cost at each step

The grid is not saved, just a single float value.
"""
DynamicGrids.@Output mutable struct SumOutput{} <: Output{T}
    gridname::Symbol | :cost
end
SumOutput(length::Integer; kwargs...) = SumOutput(; frames=zeros(length), kwargs...)

DynamicGrids.storegrid!(output::SumOutput, data::MultiSimData, f) = begin
    checkbounds(output, f)
    output[f] = sum(data[output.gridname])
end

DynamicGrids.initgrids!(output::SumOutput, init::NamedTuple) =
    output[1] = sum(init[output.gridname])
