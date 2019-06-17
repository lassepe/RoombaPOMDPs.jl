import POMDPs: action

struct FirstUp <: Policy
    m::RoombaModel
    speed::Float64
end
FirstUp(m::RoombaModel, default_action::RoombaAct) = FirstUp(m, default_action.v)

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

# the partially observable version of the policy controlling the robot
# based on the most likely state in the belief
POMDPs.action(p::FirstUp, b::AbstractParticleBelief) = POMDPs.action(p, mode(b))
