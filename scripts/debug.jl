using CSV
using DataFrames

include("$(@__DIR__)/main.jl")

function debug(sim::Sim)
    hist = simulate(sim)
    makegif(problem(sim), hist; filename="$(@__DIR__)/../gifs/debug.gif")
end

function debug(data::DataFrame, row_id::Int)
    @show row = data[row_id, :]
    sim = setup_sim(row.policy_key, row.i_run)
    debug(sim)
end

function debug(args...; kwargs...)
    @time sim = setup_sim(args...; kwargs...)
    debug(sim)
end
