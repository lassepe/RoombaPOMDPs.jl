using Revise
using AA228FinalProject
using POMDPGifs
using Random
using ParticleFilters
using POMDPPolicies
using ARDESPOT
using POMCPOW
using POMDPs

include("value_estimates.jl")

# Interesting example:
# * 111
function run(i_run::Int)
    rng = MersenneTwister(i_run)

    # problem setup
    speed = 2.0
    as = vec([RoombaAct(v, om) for v in (0.0, speed), om in (-1.0, 0.0, 1.0)])
    m = RoombaPOMDP(sensor=Bumper(), mdp=RoombaMDP(config=1, aspace=as));
    spf = SimpleParticleFilter(m, BumperResampler(6000), rng=deepcopy(rng))
    filter = RoombaParticleFilter(spf, 2.0, 0.5);

    #       # DESPOT setup with default policy rollout for lower bound estimate and constant upper bound
    #       default = FunctionPolicy(x->[speed, 0.0])
    #       rollout_bounds = IndependentBounds(DefaultPolicyLB(default), 10.0, check_terminal=true)
    #       solver = DESPOTSolver(K=20, T_max=1, bounds=rollout_bounds, rng=deepcopy(rng))
    #       planner = solve(solver, m)
    #       makegif(m, planner, filter, filename="$(@__DIR__)/../gifs/$(i_run)_despot_default_policy.gif", rng=deepcopy(rng), max_steps=200, show_progress=true)

    #       # DESPOT setup with analytic bound estimate
    #       analytic_bounds = IndependentBounds(lower_bound, upper_bound, check_terminal=true)
    #       default_action = RoombaAct(speed, 0.0)
    #       solver = DESPOTSolver(K=20, T_max=Inf, max_trials=10, default_action=default_action, bounds=analytic_bounds, rng=deepcopy(rng))
    #       planner = solve(solver, m)
    #       makegif(m, planner, filter, filename="$(@__DIR__)/../gifs/$(i_run)_despot_analytic_bounds.gif", rng=deepcopy(rng), max_steps=200, show_progress=true)

    # POMCPOW setup with analytic value estimate
    solver = POMCPOWSolver(tree_queries=5000, max_depth=50, criterion=MaxUCB(20),
                           k_observation=5, alpha_observation=1/30, enable_action_pw=false, check_repeat_obs=true,
                           check_repeat_act=true, estimate_value=estimate_value, rng=deepcopy(rng))
    planner = solve(solver, m)
    makegif(m, planner, filter, filename="$(@__DIR__)/../gifs/$(i_run)_pomcpow.gif", rng=deepcopy(rng), max_steps=200, show_progress=true)
end
