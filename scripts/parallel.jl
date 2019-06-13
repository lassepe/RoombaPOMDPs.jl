using ProgressMeter

# setup parallelization
using Distributed
const desired_nworkers = 10
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

# a simple wrapper to call things in a parallelized fashion with progress meter
function parallel_run(runs::UnitRange)
    progress_pmap(runs) do i_run
        run(i_run; show_progress=false)
    end
end
