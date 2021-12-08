using Test

using BenchmarkPlots
using Statistics

@testset "Basic" begin
    scene, layout, df = benchmarkplot(
        [median, std],
        string.([median, std]),
        rand,
        [10^i for i in 1:2],
    )
    @test length(df.N) == 2
end