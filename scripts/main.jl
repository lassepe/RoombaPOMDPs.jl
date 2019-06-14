using Revise
using AA228FinalProject
using POMDPGifs
using Random
using ParticleFilters
using POMDPPolicies
using ARDESPOT
using POMCPOW
using POMDPs
using POMDPSimulators

include("$(@__DIR__)/value_estimates.jl")
include("$(@__DIR__)/utils.jl")
include("$(@__DIR__)/heuristic_policies.jl")
# Interesting example:
# * 111

function policy_map(m::RoombaPOMDP, default_action::RoombaAct, rng::AbstractRNG)
    return Dict(
                # DESPOT setup with default policy rollout for lower bound estimate and constant upper bound
                "DESPOT_defaultPolicy" => begin
                    default = FunctionPolicy(x->default_action)
                    rollout_bounds = IndependentBounds(DefaultPolicyLB(default), 10.0, check_terminal=true)
                    solver = DESPOTSolver(K=20, T_max=1, default_action=default_action, bounds=rollout_bounds, rng=copy(rng))
                    planner = solve(solver, m)
                end,
                # DESPOT setup with analytic bound estimate
                "DESPOT_analyticBounds" => begin
                    analytic_bounds = IndependentBounds(lower_bound, upper_bound, check_terminal=true)
                    solver = DESPOTSolver(K=20, T_max=1, default_action=default_action, bounds=analytic_bounds, rng=copy(rng))
                    planner = solve(solver, m)
                end,
                # POMCPOW setup with analytic value estimate
                "POMCPOW_analyticValueEstimate" => begin
                    solver = POMCPOWSolver(tree_queries=100000,
                                           max_time=1.0,
                                           max_depth=100, criterion=MaxUCB(20),
                                           k_observation=5, alpha_observation=1/30, enable_action_pw=false, check_repeat_obs=true,
                                           check_repeat_act=true, estimate_value=estimate_value, rng=copy(rng))
                    planner = solve(solver, m)
                end,
                # Mode controlled heuristic policy
                "MostLikelyStateController" => FirstUp(m, default_action)
               )
end

function setup_sim(policy_key::String, i_run::Int)
    rng = MersenneTwister(i_run)
    # problem setup
    speed = 2.0
    as = vec([RoombaAct(v, om) for v in (0.0, speed), om in (-1.0, 0.0, 1.0)])
    m = RoombaPOMDP(sensor=Bumper(), mdp=RoombaMDP(config=1, aspace=as));
    spf = SimpleParticleFilter(m, BumperResampler(6000), rng=copy(rng))
    default_action = RoombaAct(speed, 0.0)
    filter = RoombaParticleFilter(spf, 2.0, 0.5)
    md = Dict(:i_run => i_run,
              :policy_key => policy_key)
    policy = policy_map(m, default_action, copy(rng))[policy_key]
    # compose the sim object
    return Sim(m, policy, filter; rng=copy(rng), max_steps=300, metadata=md)
end

function parallel_sim(runs::UnitRange, policy_keys)
    # setup all simulation instances
    sims = vec([setup_sim(pk, i_run) for pk in policy_keys, i_run in runs])

    return run_parallel(sims) do sim::Sim, hist::SimHistory
        return [:n_steps => n_steps(hist),
                :discounted_reward => discounted_reward(hist),
                :final_state_type => final_state_type(problem(sim), hist)]
    end
end

function final_state_type(m::RoombaPOMDP, hist::SimHistory)
    final_state = last(collect(eachstep(hist, "sp")))
    if isterminal(m, final_state)
        return is_failure_state(final_state) ? "failure" : "success"
    else
        return "nonterminal"
    end
end
