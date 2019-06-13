# the fully observable version of the first up policy
function first_up(s::RoombaState)
  # otherwise we first try to align in vertical direction
  # then in horizontal direction (to cope for the L-shape)
  goal_x, goal_y = goal_xy
  x,y,th = s[1:3]

  # apply a proportional controller with prioroty on the vertical direction
  Kprop = 1.0
  om = 0
  v = 2

  if goal_y - y > 4.5
    # first move up
    del_angle = wrap_to_pi(pi/2-th)
    om = Kprop * del_angle
  else
    ang_to_goal = atan(goal_y - y, goal_x - x)
    del_angle = wrap_to_pi(ang_to_goal - th)
    om  = Kprop * del_angle
  end
  return RoombaAct(v, om)
end

# the partially observable version of the policy controlling the robot
# based on the most likely state in the belief
first_up(b::AbstractParticleBelief) = first_up(mode(b))
