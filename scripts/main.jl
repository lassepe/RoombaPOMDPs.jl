using Revise
using AA228FinalProject
using POMDPGifs
using Random
using ParticleFilters
using POMDPPolicies
using ARDESPOT
using POMCPOW
using POMDPs

include("$(@__DIR__)/value_estimates.jl")
# Interesting example:
# * 111
function run(i_run::Int; show_progress=true)
    rng = MersenneTwister(i_run)

    # problem setup
    speed = 2.0
    as = vec([RoombaAct(v, om) for v in (0.0, speed), om in (-1.0, 0.0, 1.0)])
    m = RoombaPOMDP(sensor=Bumper(), mdp=RoombaMDP(config=1, aspace=as));
    spf = SimpleParticleFilter(m, BumperResampler(6000), rng=deepcopy(rng))
    default_action = RoombaAct(speed, 0.0)
    filter = RoombaParticleFilter(spf, 2.0, 0.5)
    file_path_and_id = "$(@__DIR__)/../gifs/$(lpad(string(i_run), 4, "0"))"

    # DESPOT setup with default policy rollout for lower bound estimate and constant upper bound
    default = FunctionPolicy(x->[speed, 0.0])
    rollout_bounds = IndependentBounds(DefaultPolicyLB(default), 10.0, check_terminal=true)
    solver = DESPOTSolver(K=20, T_max=1, default_action=default_action, bounds=rollout_bounds, rng=deepcopy(rng))
    planner = solve(solver, m)
    makegif(m, planner, filter, filename="$(file_path_and_id)_despot_default_policy.gif", rng=deepcopy(rng), max_steps=200, show_progress=true)

    # DESPOT setup with analytic bound estimate
    analytic_bounds = IndependentBounds(lower_bound, upper_bound, check_terminal=true)
    solver = DESPOTSolver(K=20, T_max=1, default_action=default_action, bounds=analytic_bounds, rng=deepcopy(rng))
    planner = solve(solver, m)
    makegif(m, planner, filter, filename="$(file_path_and_id)_despot_analytic_bounds.gif", rng=deepcopy(rng), max_steps=200, show_progress=true)

    #       # POMCPOW setup with analytic value estimate
    #       solver = POMCPOWSolver(tree_queries=6000, max_depth=50, criterion=MaxUCB(20),
    #                              k_observation=5, alpha_observation=1/30, enable_action_pw=false, check_repeat_obs=true,
    #                              check_repeat_act=true, estimate_value=estimate_value, rng=deepcopy(rng))
    #       planner = solve(solver, m)
    #       makegif(m, planner, filter, filename="$(file_path_and_id)_pomcpow.gif", rng=deepcopy(rng), max_steps=200, show_progress=show_progress)
end

function setup_run(i_run::Int)
end
