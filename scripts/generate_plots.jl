include("./analyze_results.jl")

import Cairo, Fontconfig

rename(s::String, old::String="MostLikelyStateController", new::String="MLRA") = return s == old ? new : s

function create_eval_plot(data=nothing; filename::String="$(@__DIR__)/../results/final_results/data_eval_final.csv",
                          outdir::String="$(@__DIR__)/../results/final_results/plots/",
                          dims=(14.5cm, 10cm),
                          reward_type::Symbol=:inf_discounted_reward)
    if isnothing(data)
        data = CSV.read(filename)
    end

    # value SEM
    dims = (14.5cm, 10cm)
    p = plot_results(data, show_nsteps=false, show_fst=false, show_value_violin=false, reward_type=reward_type)
    draw(PDF(joinpath(outdir, "lp_value_sem_eval_plot-$(reward_type).pdf"), dims...), p)

    # value violin
    dims = (14.5cm, 10cm)
    p = plot_results(data, show_nsteps=false, show_fst=false, show_value_sem=false, reward_type=reward_type)
    draw(PDF(joinpath(outdir, "lp_value_violin_eval_plot-$(reward_type).pdf"), dims...), p)

    # outcome histogram
    dims = (14.5cm, 8cm)
    p = plot_results(data, show_nsteps=false, show_fst=true, show_value_violin=false, show_value_sem=false, reward_type=reward_type)
    draw(PDF(joinpath(outdir, "lp_outcome_eval_plot.pdf"), dims...), p)

    # combined:
    dims = (14.5cm, 21cm)
    p = plot_results(data, show_nsteps=false, show_fst=false, reward_type=reward_type )
    draw(PDF(joinpath(outdir, "lp_value_eval_plot-$(reward_type).pdf"), dims...), p)
end

# Renaming:
#
# d = CSV.read("results/final_results/data_po.csv")
# d = @transform(d, policy_key=rename.(:policy_key, "MostLikelyStateController", "MLRA"))
# d = @transform(d, policy_key=rename.(:policy_key, "DESPOT_defaultPolicy", "DESPOT\nrollout"))
# d = @transform(d, policy_key=rename.(:policy_key, "DESPOT_analyticBounds", "DESPOT\nanalytic"))
# d = @transform(d, policy_key=rename.(:policy_key, "POMCPOW_rolloutEstimate", "POMCPOW\nrollout"))
# d = @transform(d, policy_key=rename.(:policy_key, "POMCPOW_analyticValueEstimate", "POMCPOW\nanalytic"))
# d = @transform(d, final_state_type=rename.(:final_state_type, "success", "+"))
# d = @transform(d, final_state_type=rename.(:final_state_type, "failure", "-"))
# d = @transform(d, final_state_type=rename.(:final_state_type, "nonterminal", "0"))
# d = CSV.write("results/final_results/data_eval_final.csv", d)
