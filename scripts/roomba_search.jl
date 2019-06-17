using Parameters
using AA228FinalProject
using POMDPs
using Random

using GraphSearchZero
import GraphSearchZero: start_state, is_goal_state, successors

struct RoombaNavigationProblem <: SearchProblem{RoombaState, RoombaAct}
    m::RoombaMDP
    start_state::RoombaState
end

GraphSearchZero.start_state(p::RoombaNavigationProblem) = p.start_state
GraphSearchZero.is_goal_state(p::RoombaNavigationProblem, s::RoombaState) = isterminal(p.m, s) && s.status == 1.0

function GraphSearchZero.successors(p::RoombaNavigationProblem, s::RoombaState)
    successors::Vector{Tuple{RoombaState, RoombaAct, Float64}} = []
    sizehint!(successors, n_actions(p.m))

    for a in actions(p.m)
        sp, r = generate_sr(p.m, s, a, Random.GLOBAL_RNG)
        # step cost is the negative reward
        c = -r
        push!(successors, (sp, a, c))
    end

    return successors
end
