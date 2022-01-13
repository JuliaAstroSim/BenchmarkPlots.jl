using Test

using BenchmarkPlots
using Statistics

@testset "Basic" begin
    fig, df = benchmarkplot(
        [median, std],
        string.([median, std]),
        rand,
        [10^i for i in 1:2],
    )
    @test length(df.N) == 2
end