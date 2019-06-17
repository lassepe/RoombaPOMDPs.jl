import POMDPs: action

include("$(@__DIR__)/value_estimates.jl")
include("$(@__DIR__)/roomba_search.jl")

struct FirstUp <: Policy
    m::RoombaMDP
    speed::Float64
end
FirstUp(m::RoombaMDP, default_action::RoombaAct) = FirstUp(m, default_action.v)

# the fully observable version of the first up policy
function POMDPs.action(p::FirstUp, s::RoombaState)
  # otherwise we first try to align in vertical direction
  # then in horizontal direction (to cope for the L-shape)
  goal_x, goal_y = get_goal_xy(p.m)
  x,y,th = s[1:3]

  # apply a proportional controller with prioroty on the vertical direction
  Kprop = 1.0
  om = 0

  if goal_y - y > 4.5
    # first move up
    del_angle = wrap_to_pi(pi/2-th)
    om = Kprop * del_angle
  else
    ang_to_goal = atan(goal_y - y, goal_x - x)
    del_angle = wrap_to_pi(ang_to_goal - th)
    om  = Kprop * del_angle
  end
  return RoombaAct(p.speed, om)
end

struct MLMPC <: Policy
    m::RoombaMDP
    default_action::RoombaAct
end

function POMDPs.action(p::MLMPC, s::RoombaState, debug::Bool=true)
    goal_x, goal_y = get_goal_xy(p.m)
    heuristic = (s::RoombaState) -> -value_estimate(p.m, s)
    roomba_navigation_problem = RoombaNavigationProblem(p.m, s)

    aseq::Vector{RoombaAct}, sseq::Vector{RoombaState} = try
        weighted_astar_search(roomba_navigation_problem, heuristic, 0.2)
    catch e
        if !(e isa InfeasibleSearchProblemError)
            rethrow(e)
        elseif debug
            @warn "No solution found. Using default action."
        end
        ([p.default_action], [roomba_navigation_problem.start_state])
    end

    return length(aseq) > 0 ? first(aseq) : p.default_action
end

# the partially observable version of the policy controlling the robot
# based on the most likely state in the belief
POMDPs.action(p::Policy, b::AbstractParticleBelief) = POMDPs.action(p, mode(b))
