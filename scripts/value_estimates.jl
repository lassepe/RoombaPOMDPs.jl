include("utils.jl")

function lower_bound(m::RoombaPOMDP, b::AbstractParticleBelief)
    if any(is_failure_state.(particles(b)))
        return mdp(m).stairs_penalty
    end
    # get the maximum translational speed the robot can travel at
    max_dxy = maximum(getproperty.(actions(m), :v))
    # compute the worst case number of steps to the goal (for the particle far
    # away from the goal location)
    max_steps = Int(ceil(maximum(manhattan_steps_to_goal(m, s, max_dxy) for s in particles(b))))
    # compute the corresponding reward
    # there should be some analytic formula for this
    return steps_to_reward_estimate(m, max_steps)
end

function upper_bound(m::RoombaPOMDP, b::AbstractParticleBelief)
    # get the maximum translational speed the robot can travel at
    max_dxy = maximum(getproperty.(actions(m), :v))
    # compute the best case number of steps to the goal (for the particle close
    # to the goal location)
    non_failure_distances = (manhattan_steps_to_goal(m, s, max_dxy) for s in particles(b) if !is_failure_state(s))
    if isempty(non_failure_distances)
        return mdp(m).stairs_penalty
    end
    min_steps = Int(floor(minimum(non_failure_distances) / sqrt(2)))
    # compute the corresponding reward
    # there should be some analytic formula for this
    return steps_to_reward_estimate(m, min_steps)
end

function estimate_value(m::RoombaPOMDP, s::RoombaState, b, ::Int)
    # get the maximum translational speed the robot can travel at
    max_dxy = maximum(getproperty.(actions(m), :v))
    # compute the best case number of steps to the goal (for the particle close
    # to the goal location)
    if is_failure_state(s)
        return mdp(m).stairs_penalty
    end
    min_steps = Int(floor(manhattan_steps_to_goal(m, s, max_dxy) / sqrt(2)))
    # compute the corresponding reward
    # there should be some analytic formula for this
    return steps_to_reward_estimate(m, min_steps)
end
