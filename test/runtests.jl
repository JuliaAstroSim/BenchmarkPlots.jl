using Test

using BenchmarkPlots

@testset "Basic" begin
    scene, layout, timings = benchmarkplot(
        [sum, minimum],
        rand,
        [10^i for i in 1:3],
    )
    @test sum(timings.N) == 11110
end