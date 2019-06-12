using Revise
using AA228FinalProject
using POMDPGifs
using Random
using ParticleFilters
using POMDPPolicies
using ARDESPOT
using POMDPs


# Interesting example:
#
# - 111
function run(i_run::Int)
    rng = MersenneTwister(i_run)

    # problem setup
    speed = 2.0
    as = vec([RoombaAct(v, om) for v in (0.0, speed), om in (-1.0, 0.0, 1.0)])
    m = RoombaPOMDP(sensor=Bumper(), mdp=RoombaMDP(config=1, aspace=as, contact_pen=-0.1));

    # DESPOT setup with straight default policy
    default = FunctionPolicy(x->[speed, 0.0])
    bounds = IndependentBounds(DefaultPolicyLB(default), 10.0, check_terminal=true)
    solver = DESPOTSolver(K=20, T_max=1, bounds=bounds, rng=deepcopy(rng))
    planner = solve(solver, m)
    spf = SimpleParticleFilter(m, BumperResampler(5000), rng=deepcopy(rng))
    filter = RoombaParticleFilter(spf, 2.0, 0.5);
    makegif(m, planner, filter, filename="$(@__DIR__)/../$(i_run)_despot_default_policy.gif", rng=deepcopy(rng), max_steps=200, show_progress=true)
end
