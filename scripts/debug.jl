using CSV
using DataFrames

include("$(@__DIR__)/main.jl")

function debug(sim::Sim; filename="$(@__DIR__)/../gifs/debug.gif")
    @time hist = simulate(sim)
    makegif(problem(sim), hist; filename=filename, fps=10)
end

function debug(data::DataFrame, row_id::Int; filename="$(@__DIR__)/../gifs/debug.gif")
    @show row = data[row_id, :]
    sim = setup_sim(row.policy_key, row.i_run)
    debug(sim; filename=filename)
end

function debug(sim_setup_args...; filename::String="$(@__DIR__)/../gifs/debug.gif", sim_setup_kwargs...)
    sim = setup_sim(sim_setup_args...; sim_setup_kwargs...)
    debug(sim; filename=filename)
end
