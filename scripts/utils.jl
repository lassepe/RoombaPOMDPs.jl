using LinearAlgebra
using AA228FinalProject

is_failure_state(s::RoombaState) = s.status == -1.0

function steps_to_goal(m::RoombaModel, s::RoombaState, max_dxy::Real, p::Real=1)
    @assert max_dxy > 0
    if s.status == 1.0
        # we already are at the goal, no more steps to take
        return 0
    elseif is_failure_state(s)
        error("The state handed for estimation is an absorbing non-goal state!")
    end
    # the goal position
    gx, gy = get_goal_xy(m)
    dist_to_goal = norm((s.x - gx, s.y - gy), p)
    # estimated number of steps to goal:
    return dist_to_goal / max_dxy
end

function steps_to_reward_estimate(m, n_steps::Int)
    @assert n_steps >= 0
    if iszero(n_steps)
        return mdp(m).goal_reward
    end
    return sum(mdp(m).time_pen*discount(m)^(i-1) for i in 1:n_steps) + mdp(m).goal_reward*discount(m)^n_steps
end
