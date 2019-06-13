using DataFrames
using DataFramesMeta
using Gadfly
using CSV
using Statistics

function plot_results(data::DataFrame)
	Gadfly.set_default_plot_size(30cm,30cm)
	detailed_theme = Gadfly.Theme(minor_label_font_size=8pt, key_position=:none)

    # Collect some statistics. One row per policy key
	df_stats = DataFrame(policy_key=String[], MeanValue=Float64[], SEMValue=Float64[])
	for policy_key in unique(data.policy_key)
        value = (@linq data |> where(:policy_key .== policy_key))[:discounted_reward]
        push!(df_stats, (policy_key, mean(value), std(value)/sqrt(size(value, 1))))
	end

    value_errorbar_plot = plot(x=df_stats.policy_key, y=df_stats.MeanValue,
                 ymin=(df_stats.MeanValue - df_stats.SEMValue), ymax=(df_stats.MeanValue + df_stats.SEMValue),
                 color=df_stats.policy_key, Geom.point, Geom.errorbar, Guide.xlabel("Compute"), Guide.ylabel("Value"))

    value_boxplot = plot(data, x=:policy_key, y=:discounted_reward, color=:policy_key, Geom.violin)

    final_state_type_plot = plot(data, xgroup=:policy_key, x=:final_state_type,
                                 # color=:policy_key,
                                 Geom.subplot_grid(Geom.histogram),
                                 Gadfly.Theme(major_label_font_size=8pt,
                                              minor_label_font_size=8pt,
                                              key_position=:none))

    display(vstack(value_boxplot, final_state_type_plot))
end