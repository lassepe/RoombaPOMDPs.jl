using AA228FinalProject

include("utils.jl")

function lower_bound(m::RoombaPOMDP, b::AbstractParticleBelief)
    if any(is_failure_state.(particles(b)))
        return mdp(m).stairs_penalty
    end
    # get the maximum translational speed the robot can travel at
    max_dxy = maximum_step(m)
    # compute the worst case number of steps to the goal (for the particle far
    # away from the goal location)
    max_steps = Int(ceil(maximum(steps_to_goal(m, s, max_dxy, 1) for s in particles(b))))
    # compute the corresponding reward
    # there should be some analytic formula for this
    return steps_to_reward_estimate(m, max_steps)
end

function upper_bound(m::RoombaPOMDP, b::AbstractParticleBelief)
    # get the maximum translational speed the robot can travel at
    max_dxy = maximum_step(m)
    # compute the best case number of steps to the goal (for the particle close
    # to the goal location)
    non_failure_distances = (steps_to_goal(m, s, max_dxy, 2) for s in particles(b) if !is_failure_state(s))
    if isempty(non_failure_distances)
        return mdp(m).stairs_penalty
    end
    min_steps = Int(floor(minimum(non_failure_distances)))
    # compute the corresponding reward
    # there should be some analytic formula for this
    return steps_to_reward_estimate(m, min_steps)
end

function value_estimate(m::RoombaModel, s::RoombaState, b=Nothing, ::Int=0)
    # get the maximum translational speed the robot can travel at
    max_dxy = maximum_step(m)
    # compute the best case number of steps to the goal (for the particle close
    # to the goal location)
    if is_failure_state(s)
        return mdp(m).stairs_penalty
    end

    min_steps = Int(floor(steps_to_goal(m, s, max_dxy, 1)))
    # compute the corresponding reward
    # there should be some analytic formula for this
    return steps_to_reward_estimate(m, min_steps)
end

function search_value_estimate(m::RoombaModel, s::RoombaState, b=Nothing, ::Int=0)
    goal_x, goal_y = get_goal_xy(m)
    heuristic = (s::RoombaState) -> -value_estimate(m, s)
    roomba_navigation_problem = RoombaNavigationProblem(mdp(m), s)

    aseq::Vector{RoombaAct}, sseq::Vector{RoombaState}, c = try
        weighted_astar_search(roomba_navigation_problem, heuristic, 0.2)
    catch e
        if !(e isa InfeasibleSearchProblemError)
            rethrow(e)
        else
            @warn "No solution found. Using default action."
        end
        ([p.default_action], [roomba_navigation_problem.start_state], 0)
    end

    # the reward estimate is the negative cost
    return length(aseq) > 0 ? -c : 0
end

maximum_step(m) = maximum(getproperty.(actions(m), :v))
