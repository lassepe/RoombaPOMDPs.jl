using DataFrames
using DataFramesMeta
using Gadfly
using CSV
using Statistics

function plot_results(data::DataFrame;
                      reward_type::Symbol=:discounted_reward,
                      show_value_sem::Bool=true, show_value_violin::Bool=true,
                      show_nsteps::Bool=true, show_fst::Bool=true)
    plot_stack = []

	Gadfly.set_default_plot_size(40cm,30cm)
    detailed_theme = Gadfly.Theme(major_label_font="CMU Serif",
                                  minor_label_font="CMU Serif",
                                  major_label_font_size=12pt,
                                  minor_label_font_size=12pt, key_position=:none)

    # Collect some statistics. One row per policy key
	df_stats = DataFrame(policy_key=String[], MeanValue=Float64[], SEMValue=Float64[])
	for policy_key in unique(data.policy_key)
        value = (@linq data |> where(:policy_key .== policy_key))[reward_type]
        push!(df_stats, (policy_key, mean(value), std(value)/sqrt(size(value, 1))))
	end

    if show_value_sem
        # Error bar plot includid SEM
        value_errorbar_plot = plot(x=df_stats.policy_key, y=df_stats.MeanValue,
                                   ymin=(df_stats.MeanValue - df_stats.SEMValue), ymax=(df_stats.MeanValue + df_stats.SEMValue),
                                   color=df_stats.policy_key, Geom.point, Geom.errorbar, Guide.xlabel("Policy"), Guide.ylabel("Cumulative Discounted Reward"),
                                   detailed_theme)
        push!(plot_stack, value_errorbar_plot)
    end

    if show_value_violin
        # violin plot for reward distribution
        value_violin_plot = plot(data, x=:policy_key, y=reward_type, color=:policy_key, Geom.violin, detailed_theme)
        push!(plot_stack, value_violin_plot)
    end

    if show_nsteps
        nsteps_violin_plot = plot(data, x=:policy_key, y=:n_steps, color=:policy_key, Geom.violin, detailed_theme)
        push!(plot_stack, nsteps_violin_plot)
    end

    if show_fst
        # historgram over success
        final_state_type_plot = plot(data, xgroup=:policy_key, x=:final_state_type,
                                     color=:policy_key,
                                     Geom.subplot_grid(Geom.histogram), detailed_theme)
        push!(plot_stack, final_state_type_plot)
    end

    vstack(plot_stack...)
end

function transform_data(data::DataFrame)
    # for policies that failed to exit within the set time horizon, we adjust
    # the return by adding the living penalty over the infinite horizon
    data_transformed = @transform(data, inf_discounted_reward = (:discounted_reward .- ((:final_state_type .== "nonterminal").*(10).*(0.99.^:n_steps))))
end

