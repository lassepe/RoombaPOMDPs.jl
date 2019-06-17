# setup parallelization
using CSV
using ArgParse
using Dates
using Distributed

import Base: convert

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--runs"
            help = "The runs to perform."
            arg_type = UnitRange{Int}
            required = true
            eval_arg = true
        "--policy_keys"
            help = "The policy keys to be used."
            arg_type = Vector{String}
            eval_arg = true
            default = ["DESPOT_defaultPolicy", "DESPOT_analyticBounds",
                       "POMCPOW_rolloutEstimate", "POMCPOW_analyticValueEstimate",
                       "MostLikelyStateController", "MLMPC"]
        "--fully_observed"
            help = "Flag to indicate that a fully observed simulation is to be run."
            action = :store_true
    end

    return parse_args(s)
end

function desired_nworkers()
    desired_nworkers = Dict("lassepe-x1" => 10, "Dragan-DGX-Station" => 35)
    # lookup host name in desired worker map. Otherwise, don't parallelize
    return get(desired_nworkers, gethostname(), 1)
end

const IN_SLURM = "SLURM_JOBID" in keys(ENV)
IN_SLURM && using ClusterManagers
if IN_SLURM
    pids = addprocs_slurm(parse(Int, ENV["SLURM_NTASKS"]))
    print("\n")
else
    if nworkers() != desired_nworkers()
        wait(rmprocs(workers()))
        pids = addprocs(desired_nworkers())
    else
        pids = []
    end
end
@info "Started $(nworkers()) workers..."
@info "Precompiling simulation code..."
@everywhere begin
    using Pkg
    Pkg.activate(".")
    include("$(@__DIR__)/main.jl")
end

function main()
    parsed_args = parse_commandline()
    runs = parsed_args["runs"]
    policy_keys = parsed_args["policy_keys"]
    fully_observed = parsed_args["fully_observed"]

    @info "Running simulations..."
    data = parallel_sim(runs, policy_keys; fully_observed=fully_observed)
    @info "Writing data..."
    result_dir = realpath("$(@__DIR__)/../results/")
    filename = "sim_results-$(runs)-$(now())-$(join(policy_keys, "_"))$(fully_observed ? "-FULLY_OBSERVED" : "")-$(gethostname()).csv"
    file = CSV.write(joinpath(result_dir, filename), data)
    @info "All done! Results written to: $file."
end

main()

rmprocs(pids)
