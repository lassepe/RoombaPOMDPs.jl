# setup parallelization
using CSV
using Dates
using Distributed
const desired_nworkers = 35
const IN_SLURM = "SLURM_JOBID" in keys(ENV)
IN_SLURM && using ClusterManagers
if IN_SLURM
    pids = addprocs_slurm(parse(Int, ENV["SLURM_NTASKS"]))
    print("\n")
else
    if nworkers() != desired_nworkers
        wait(rmprocs(workers()))
        pids = addprocs(desired_nworkers)
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
    policy_keys = ["DESPOT_defaultPolicy", "DESPOT_analyticBounds", "POMCPOW_analyticValueEstimate"]
    @info "Running simulations..."
    data = parallel_sim(101:200, policy_keys)
    @info "Writing data..."
    result_dir = realpath("$(@__DIR__)/../results/")
    file_name = "sim_results-$(gethostname())-$(now())-$(join(policy_keys, "_")).csv"
    file = CSV.write(joinpath(result_dir, file_name), data)
    @info "All done! Wrote results to $file."
end

main()

rmprocs(pids)
