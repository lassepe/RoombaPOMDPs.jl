include("./analyze_results.jl")

import Cairo, Fontconfig

rename(s::String, old::String="MostLikelyStateController", new::String="MLRA") = return s == old ? new : s

function create_eval_plot(;filename::String="$(@__DIR__)/../results/final_results/data_eval_final.csv",
                          outname::String="$(@__DIR__)/../results/final_results/plots/lp_eval_plot.svg",
                          dims=(30cm, 20cm))
    data_po = CSV.read(filename)
    p = plot_results(data_po, show_nsteps=false, show_fst=false)
    draw(SVG(outname, dims...), p)
    #run(`xdg-open $outname`)
end
