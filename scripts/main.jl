using Revise
using AA228FinalProject
using POMDPGifs
using Random
using ParticleFilters
using POMDPPolicies
using ARDESPOT
using POMCPOW
using MCTS
using POMDPs
using POMDPSimulators

include("$(@__DIR__)/value_estimates.jl")
include("$(@__DIR__)/utils.jl")
include("$(@__DIR__)/ml_heuristic_policies.jl")
# Interesting example:
# * 111

function policy_map(m::RoombaModel, default_action::RoombaAct, rng::AbstractRNG, key::String)
    rollout_policy = FunctionPolicy(x->default_action)
    if key == "DESPOT_defaultPolicy"
        @assert m isa RoombaPOMDP
        # DESPOT setup with default policy rollout for lower bound estimate and constant upper bound
        rollout_bounds = IndependentBounds(DefaultPolicyLB(rollout_policy), upper_bound, check_terminal=true)
        solver = DESPOTSolver(K=20, T_max=1, default_action=default_action, bounds=rollout_bounds, rng=copy(rng))
        return solve(solver, m)
    elseif key == "DESPOT_analyticBounds"
        @assert m isa RoombaPOMDP
        # DESPOT setup with analytic bound estimate
        analytic_bounds = IndependentBounds(lower_bound, upper_bound, check_terminal=true)
        solver = DESPOTSolver(K=20, T_max=1, default_action=default_action, bounds=analytic_bounds, rng=copy(rng))
        return solve(solver, m)
    elseif key == "POMCPOW_rolloutEstimate"
        @assert m isa RoombaPOMDP
        # POMCPOW setup with default policy rollout for value estimate
        solver = POMCPOWSolver(default_action=default_action,
                               tree_queries=100000,
                               max_time=1,
                               max_depth=100, criterion=MaxUCB(20),
                               k_observation=5, alpha_observation=1/30, enable_action_pw=false, check_repeat_obs=true,
                               check_repeat_act=true, estimate_value=FORollout(rollout_policy), rng=copy(rng))
        return solve(solver, m)
    elseif key == "POMCPOW_analyticValueEstimate"
        @assert m isa RoombaPOMDP
        # POMCPOW setup with analytic value estimate
        solver = POMCPOWSolver(default_action=default_action,
                               tree_queries=100000,
                               max_time=1,
                               max_depth=100, criterion=MaxUCB(20),
                               k_observation=5, alpha_observation=1/30, enable_action_pw=false, check_repeat_obs=true,
                               check_repeat_act=true, estimate_value=value_estimate, rng=copy(rng))
        return solve(solver, m)
    elseif key == "MostLikelyStateController"
        # Mode controlled heuristic policy
        return FirstUp(mdp(m), default_action)
    elseif key == "MLMPC"
        return MLMPC(mdp(m), default_action)
    else
        error("Illegal policy key.")
    end
end

function setup_sim(policy_key::String, i_run::Int; fully_observed::Bool=false)
    rng = MersenneTwister(i_run)
    # problem setup
    max_steps = 300
    speed = 2.0
    as = vec([RoombaAct(v, om) for v in (speed,), om in (-1.0, 0.0, 1.0)])
    mdp = RoombaMDP(config=1, aspace=as)
    default_action = RoombaAct(speed, 0.0)
    md = Dict(:i_run => i_run,
              :policy_key => policy_key)
    if fully_observed
        m = mdp
    else
        m = RoombaPOMDP(sensor=Bumper(), mdp=mdp)
        spf = SimpleParticleFilter(m, BumperResampler(6000), rng=copy(rng))
        filter = RoombaParticleFilter(spf, 2.0, 0.5)
    end
    policy = policy_map(m, default_action, copy(rng), policy_key)
    # compose the sim object
    return fully_observed ? Sim(m, policy;         rng=copy(rng), max_steps=max_steps, metadata=md) :
                            Sim(m, policy, filter; rng=copy(rng), max_steps=max_steps, metadata=md)
end

function parallel_sim(runs::UnitRange, policy_keys; kwargs...)
    # setup all simulation instances
    sims = vec([setup_sim(pk, i_run; kwargs...) for pk in policy_keys, i_run in runs])

    return run_parallel(sims) do sim::Sim, hist::SimHistory
        return [:n_steps => n_steps(hist),
                :discounted_reward => discounted_reward(hist),
                :undiscounted_reward => undiscounted_reward(hist),
                :final_state_type => final_state_type(problem(sim), hist)]
    end
end

function final_state_type(m::RoombaModel, hist::SimHistory)
    final_state = last(collect(eachstep(hist, "sp")))
    if isterminal(m, final_state)
        return is_failure_state(final_state) ? "failure" : "success"
    else
        return "nonterminal"
    end
end
