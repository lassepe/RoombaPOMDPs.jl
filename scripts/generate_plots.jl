include("./analyze_results.jl")

import Cairo, Fontconfig

rename(s::String, old::String="MostLikelyStateController", new::String="MLRA") = return s == old ? new : s

function create_eval_plot(;filename::String="$(@__DIR__)/../results/final_results/data_eval_final.csv",
                          outname::String="$(@__DIR__)/../results/final_results/plots/lp_eval_plot.pdf",
                          dims=(25cm, 15cm))
    data_po = CSV.read(filename)
    p = plot_results(data_po, show_nsteps=false, show_fst=false)
    draw(PDF(outname, dims...), p)
    #run(`xdg-open $outname`)
end

# Renaming:
#
# d = CSV.read("results/final_results/data_po.csv")
# d = @transform(d, policy_key=rename.(:policy_key, "MostLikelyStateController", "MLRA"))
# d = @transform(d, policy_key=rename.(:policy_key, "DESPOT_defaultPolicy", "DESPOT-rollout"))
# d = @transform(d, policy_key=rename.(:policy_key, "DESPOT_defaultPolicy", "DESPOT-rollout"))
# d = @transform(d, policy_key=rename.(:policy_key, "POMCPOW_rolloutEstimate", "POMCPOW-rollout"))
# d = @transform(d, policy_key=rename.(:policy_key, "POMCPOW_analyticValueEstimate", "POMCPOW-analytic"))
# d = CSV.write("results/final_results/data_eval_final.csv")
