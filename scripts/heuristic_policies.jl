
# define a better rollout policy that first goes up and then right (highly overfitted to this problem)
struct FirstUp <: Policy end

function POMDPs.action(p::FirstUp, s::RoombaState)::RoombaAct
  # otherwise we first try to align in vertical direction
  # then in horizontal direction (to cope for the L-shape)
  goal_x, goal_y = goal_xy
  x,y,th = s[1:3]

  # apply a proportional controller with prioroty on the vertical direction
  Kprop = 1.0

  om = 0
  v = 5

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

function POMDPs.action(p::FirstUp, b::AbstractParticleBelief{RoombaState})::RoombaAct
  # if the covariance of the belief is too high, we turn aroundn for localization
  cov_diag = get_cov_diag(b)
  # increment the time counter
  if cov_diag > 1
      return RoombaAct(0., omlist[1]) # (v, om)
  end

  # otherwise we first try to align in vertical direction
  # then in horizontal direction (to cope for the L-shape)
  s = mean(b)
  return POMDPs.action(p, s)
end
