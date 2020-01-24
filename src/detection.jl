abstract type DetectionModel end

"""
    isdetected(d::DetectionModel, data, population, ntraps)

Determine whether a particular population level is detected.
"""
function isdetected end

@columns struct ThresholdDetection{T} <: DetectionModel
    # Field      | Default | Flatten | Limits         | Description
    threshold::T | 100.0   | true    | (1.0, 10000.0) | "Number of individuals required in a cell before detection"
end

isdetected(d::ThresholdDetection, population, ntraps) = population >= d.threshold

@columns struct ProbabilisticDetection{R,C} <: DetectionModel
    # Field           | Default     | Flatten | Limits       | Description
    detection_rate::R | 0.1         | false   | (0.0, 1.0)   | "Rate of detection per trap"
    trap_coverage::C  | 3.333333e-6 | false   | (0.0, 100.0) | "Proportion of cell coveraged by a single trap"
end

isdetected(d::ProbabilisticDetection, population, ntraps) = begin
    p = 1 - ((1 - d.detection_rate)^ntraps)^(population * d.trap_coverage)
    rand(Binomial(1, p)) == 1
end

@description @limits @flattenable struct Detection{Keys,S,M,T,D} <: PartialInteraction{Keys}
    # Field          | Flatten | Limits       | Description
    sites::S         | false   | _            | "Site matrix. Generated from meantraps and sitemask"
    sitemask::M      | false   | _            | "Boolean mask matrix of areas where sites would actually be placed"
    meantraps::T     | true    | (0.0, 100.0) | "Value of mean traps per site used in generating random trap coverage"
    detectionmode::D | true    | _            | "Model used to determine detection"
end
Detection(; population=:population, detected=:detected,
            sites=nothing, sitemask, meantraps=1, detectionmode=ThresholdDetection()) =
    Detection{(population, detected)}(sites, sitemask, meantraps, detectionmode)
Detection{Keys}(sites::S, sitemask::M, meantraps::T, detectionmode::D) where {Keys,S,M,T,D} = begin
    sites = build_sites!(sites, sitemask, meantraps)
    Detection{Keys,typeof(sites),M,T,D}(sites, sitemask, meantraps, detectionmode)
end

build_sites!(sites::Nothing, sitemask::Nothing, meantraps) =
    throw(ArgumentError("Must include either a `sites` or `sitemask` array"))
build_sites!(sites, sitemask::Nothing, meantraps) = sites
build_sites!(sites::Nothing, sitemask, meantraps) =
    build_sites!(similar(sitemask, Int8), sitemask, meantraps)
build_sites!(sites::AbstractArray, sitemask::AbstractArray, meantraps) = begin
    fill!(sites, false)
    for i = 1:length(sites)
        if !isnothing(mask) && sitemask[i]
            sites[i] = rand(Poisson(meantraps))
        end
    end
    sites
end

@inline applyinteraction!(interaction::Detection{Key}, data::MultiSimData, (population, detected), index) where Key = begin
    POPULATION, DETECTED = 1, 2
    detected && return # Exit if something has allready been detected
    ntraps = interaction.sites[index...]
    ntraps == 0 && return # Exit if there no traps in the cell
    if isdetected(interaction.detectionmode, population, ntraps)
        data[DETECTED][index...] = true
    end
    return
end
