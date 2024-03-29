using DataFrames
using DataFramesMeta
using Gadfly, Compose
using CSV
using Statistics
using LaTeXStrings

function plot_results(data::DataFrame;
                      reward_type::Symbol=:inf_discounted_reward,
                      show_value_sem::Bool=true, show_value_violin::Bool=true,
                      show_nsteps::Bool=true, show_fst::Bool=true)

    reward_type_string = "Cumulative $(reward_type == :undiscounted_reward ? "Undiscounted" : "Discounted") Reward"
    legend_guide = Guide.colorkey(title="Legend")
    xticks_guide = Guide.xticks(orientation=:horizontal)
    default_font = "cmr10"


    plot_stack = []
    default_theme = Gadfly.Theme(key_max_columns=6,
                                 plot_padding=[0mm],
                                 key_title_font=default_font,
                                 key_title_font_size=0mm,
                                 key_label_font=default_font,
                                 key_label_font_size=10pt,
                                 major_label_font=default_font,
                                 minor_label_font=default_font,
                                 major_label_font_size=10pt,
                                 minor_label_font_size=8pt, key_position=:none)

    # and some more for the remaining plots
    for i in 1:10
        Gadfly.push_theme(default_theme)
    end
    # the theme for the first plot
    first_plot_theme = copy(default_theme)
    first_plot_theme.key_position=:top
    Gadfly.push_theme(first_plot_theme)

    fst_theme = copy(first_plot_theme)
    fst_theme.major_label_font_size=8pt


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
                                   color=df_stats.policy_key, Geom.point, Geom.errorbar, Guide.xlabel("Policy"), Guide.ylabel("$reward_type_string (SEM)", orientation=:vertical),
                                   legend_guide, xticks_guide)
        push!(plot_stack, value_errorbar_plot)
        Gadfly.pop_theme()
    end

    if show_value_violin
        # violin plot for reward distribution
        value_violin_plot = plot(data, x=:policy_key, y=reward_type, color=:policy_key, Geom.violin,
                                 Guide.xlabel("Policy"), Guide.ylabel("$reward_type_string (PDF)", orientation=:vertical),
                                 legend_guide, xticks_guide)
        push!(plot_stack, value_violin_plot)
        Gadfly.pop_theme()
    end

    if show_nsteps
        nsteps_violin_plot = plot(data, x=:policy_key, y=:n_steps, color=:policy_key, Geom.violin)
        push!(plot_stack, nsteps_violin_plot)
        Gadfly.pop_theme()
    end

    if show_fst
        # historgram over success
        final_state_type_plot = plot(data, xgroup=:policy_key, x=:final_state_type,
                                     color=:policy_key,
                                     Geom.subplot_grid(Guide.xticks(orientation=:horizontal), Geom.histogram),
                                     fst_theme,
                                     Guide.xlabel("Outcome 𝐛𝐲 Policy"))
        push!(plot_stack, final_state_type_plot)
        Gadfly.pop_theme()
    end

    vstack(plot_stack...)
end

function transform_data(data::DataFrame)
    # for policies that failed to exit within the set time horizon, we adjust
    # the return by adding the living penalty over the infinite horizon
    data_transformed = @transform(data, inf_discounted_reward = (:discounted_reward .- ((:final_state_type .== "nonterminal").*(10).*(0.99.^:n_steps))))
end

