module BenchmarkPlots

using BenchmarkTools
using ProgressMeter
using GLMakie
using Colors
using ColorSchemes
using DataFrames
using CSV

export
    benchmark,
    benchmarkplot!,
    benchmarkplot


# Source codes

function benchmarkplot!(ax, df::DataFrame;
        colors = nothing,
        logscale = true,
        kw...
    )
    NumFuncs = size(df)[2] - 1
    if isnothing(colors)
        colors = [RGB(rand(3)...) for i in 1:NumFuncs]
    else
        if length(colors) < NumFuncs
            colors = [colors...; [RGB(rand(3)...) for i in 1:NumFuncs-length(colors)]]
        end
    end

    if logscale
        plots = [Makie.lines!(ax, log10.(df.N), log10.(df[!,i+1]); color = colors[i], kw...) for i in 1:NumFuncs]
    else
        plots = [Makie.lines!(ax, df.N, df[!,i+1]; color = colors[i], kw...) for i in 1:NumFuncs]
    end

    return plots
end

function benchmark(Functions::Array, Names::Array, gens::Array, NumData::Array)
    df = DataFrame(N = NumData)
    for f in Names
        df[:, string(f)] = zeros(length(NumData))
    end


    progress = Progress(length(NumData) * length(Functions))
    for k in eachindex(NumData)
        for i in eachindex(Functions)
            let data = gens[i](NumData[k])
                f = Functions[i]
                next!(progress; showvalues = [("NumData", NumData[k]), ("Function", string(f))])
                if data isa Tuple
                    result = @benchmark ($f)($(data)...)
                else
                    result = @benchmark ($f)($(data))
                end
                @inbounds df[k,i+1] = mean(result.times)
            end
        end
    end
    return df
end

"""
    benchmarkplot(Functions::Array, Names::Array, gen::Union{Function,Array}, NumData::Array; kw...)

Benchmark multiple `Functions` using different lengths of data generated by function `gen`.
NumData is an `Array` or other iteratables. Returns a `Tuple` of `(fig, df)`.

# Core Algorithm
For each element in `NumData`:
1. `gen` generates data with length corresponded 
2. `BenchmarkTools.@benchmark` tunes each function in `Functions` and restore timings in an array
3. Plot figure

# Keywords
- `title`: figure title. Default is `"Benchmark"`
- `logscale`: If `true`, plot axes in log10 scale. Default is `true`.
- `xlabel`: label of x-axis. Default is `logscale ? "log10(N)" : "N"`
- `ylabel`: label of y-axis. Default is `logscale ? "log10(Timing [ns])" : "Timing [ns]"`
- `size`: figure size. Default is `(1600, 900)`
- `Names`: alternative names of testing functions. Default is `string.(Functions)`, which is exactly the same with function names
- `colors`: colors of each benchmark line. Default is `nothing`, meaning random colors are assigned to lines.
- `savelog::Bool`: If `true`, save processed data in `csv`. The name of logging file depends on analysis function
- `savefolder`: set the directory to save logging file
- `stairplot`: If `true`, plot line in stair style (which is more concrete). Default is `true`
- `legend`: If `tree`, add legend to the plot
- `loadfromfile`: Path to the file of benchmark result. If `nothing`, run a new benchmark.

# Examples
```jl
using BenchmarkPlots, Makie
fig, df = benchmarkplot(
    [sum, minimum],
    rand,
    [10^i for i in 1:4],
)
display(fig)
display(df)
Makie.save("benchmark_sum_miminum.png", fig)
```
"""
function benchmarkplot(Functions::Array, Names::Array, gen::Union{Function,Array}, NumData::Array;
        title = "Benchmark",
        size = (1600, 900),
        colors = ColorSchemes.tab10.colors,
        logscale::Bool = true,
        xlabel::String = logscale ? "log10(N)" : "N",
        ylabel::String = logscale ? "log10(Timing [ns])" : "Timing [ns]",
        savelog::Bool = true,
        savefolder::String = pwd(),
        stairplot::Bool = true, #TODO
        legend::Bool = true,
        loadfromfile = nothing,
        kw...
    )
    # Initialize plotting
    fig = Figure(;size)
    ax = GLMakie.Axis(
        fig[1,1]; title, xlabel, ylabel
    )
    
    if gen isa Function
        gens = [gen for f in Functions]
    elseif gen isa Array
        @assert length(gen) == length(Functions) "Data generators `gen` must have the same length with `Functions`"
        gens = gen
    end

    if isnothing(loadfromfile)
        df = benchmark(Functions, Names, gens, NumData)
    else
        df = DataFrame(CSV.File(loadfromfile))
    end

    if savelog
        outputfile = joinpath(savefolder, "benchmark.csv")
        CSV.write(outputfile, df)
        println("Benchmark timings saved to ", outputfile)
    end

    # Plot data
    plots = benchmarkplot!(ax, df; colors, logscale, kw...)
    if legend
        leg = Legend(fig[1,2], plots, Names)
    end

    return fig, df
end

end # module
