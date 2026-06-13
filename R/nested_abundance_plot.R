#' Create a nested abundance plot
#'
#' Create a faceted abundance plot using nested grouping variables. The function
#' automatically splits the plot by a higher-level grouping variable, draws one
#' nested plot per group, adds a shared y-axis and legend, and combines all
#' panels with patchwork.
#'
#' @param data Data frame in long format.
#' @param x_col Column mapped to the x-axis.
#' @param y_col Column mapped to the y-axis.
#' @param fill_col Column used for fill colours.
#' @param split_col Column used to split the plot into separate panels.
#' @param nested_cols Character vector of columns used as nested facets.
#' @param y_label Label for the y-axis.
#' @param fill_label Label for the legend. If `NULL`, the fill column name is used.
#' @param y_limits Numeric vector of length 2 giving y-axis limits.
#' @param y_breaks Numeric vector specifying y-axis breaks.
#' @param season_gap Relative spacing between split panels.
#' @param split_width_mode How to size split panels. Use `"equal"` for equal
#'   widths or `"proportional"` to size panels by the number of x-axis groups.
#' @param min_split_width Minimum relative width for each split panel when
#'   `split_width_mode = "proportional"`.
#' @param layout_widths Numeric vector of length 3 controlling widths of y-axis,
#'   main panel, and legend.
#' @param bar_width Width of abundance bars.
#' @param x_expand Expansion for the discrete x-axis. Increase this to add more
#'   spacing around x-axis categories within each facet.
#' @param x_padding Padding inside the left and right sides of each panel.
#'   Passed to `scale_x_discrete(expand = expansion(add = ...))`.
#'   If supplied, this overrides `x_expand`.
#' @param y_padding Padding inside the lower and upper sides of each panel.
#'   Passed to `scale_y_continuous(expand = expansion(mult = ...))`.
#' @param palette Optional named vector of fill colours. Names should match the
#'   values in `fill_col`. Ignored if `fill_scale` is supplied.
#' @param fill_scale Optional ggplot2 fill scale, such as
#'   `ggplot2::scale_fill_brewer()` or `ggplot2::scale_fill_manual()`.
#' @param colour_scale Optional ggplot2 colour scale for future extensions or
#'   plots that use colour aesthetics.
#' @param plot_theme Optional ggplot2 theme object applied after package
#'   defaults. Useful for modifying text, axes, legends, margins, and other
#'   theme elements.
#' @param nest_line_colour Colour of nested facet connector lines.
#' @param nest_line_linetype Linetype of nested facet connector lines.
#' @param nest_line_linewidth Linewidth of nested facet connector lines.
#' @param strip_fill Fill colour for nested strip backgrounds.
#' @param strip_colour Border colour for nested strip backgrounds.
#' @param strip_text_colour Text colour for nested strip labels.
#' @param strip_text_face Font face for nested strip labels.
#' @param strip_text_size Text size for nested strip labels.
#' @param border_colour Colour of the border around each split plot.
#' @param border_linewidth Linewidth of the border around each split plot.
#' @param plot_margin Margin around each split plot, inside the outer plot
#'   layout. Increasing this can prevent strip text from touching the border.
#'
#' @return A patchwork object containing the combined abundance plot.
#'
#' @details
#' The input data must be in long format with one row per observation. The split
#' column is rendered as separate plot blocks, while the nested columns are
#' rendered using [ggh4x::facet_nested()]. All split panels share the same y-axis
#' limits.
#'
#' Colours can be controlled in three ways:
#'
#' 1. Leave `palette` and `fill_scale` as `NULL` to use the default ggplot2 fill colours.
#' 2. Provide a named vector to `palette`.
#' 3. Provide a full ggplot2 scale to `fill_scale`.
#'
#' If both `palette` and `fill_scale` are supplied, `fill_scale` is used.
#'
#' @examples
#' \dontrun{
#' p <- nested_abundance_plot(
#'   data = plot_df,
#'   x_col = Duplicate,
#'   y_col = RelAbund,
#'   fill_col = Phylum,
#'   split_col = Season,
#'   nested_cols = c("Location", "Week")
#' )
#'
#' my_palette <- c(
#'   Bacillota = "#f38400",
#'   Bacteroidota = "#be0032",
#'   Pseudomonadota = "#0067a5"
#' )
#'
#' p2 <- nested_abundance_plot(
#'   data = plot_df,
#'   x_col = Duplicate,
#'   y_col = RelAbund,
#'   fill_col = Phylum,
#'   split_col = Season,
#'   nested_cols = c("Location", "Week"),
#'   palette = my_palette,
#'   plot_theme = ggplot2::theme(
#'     axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
#'   )
#' )
#'
#' p3 <- nested_abundance_plot(
#'   data = plot_df,
#'   x_col = Duplicate,
#'   y_col = RelAbund,
#'   fill_col = Phylum,
#'   split_col = Season,
#'   nested_cols = c("Location", "Week"),
#'   fill_scale = ggplot2::scale_fill_brewer(palette = "Set3")
#' )
#' }
#'
#' @importFrom rlang .data
#' @export
nested_abundance_plot <- function(
  data,
  x_col,
  y_col,
  fill_col,
  split_col,
  nested_cols,
  y_label = "Relative abundance",
  fill_label = NULL,
  y_limits = c(0, 1),
  y_breaks = seq(0, 1, 0.2),
  season_gap = 0.02,
  split_width_mode = "proportional",
  min_split_width = 1,
  layout_widths = c(0.01, 1, 0.18),
  bar_width = 0.95,
  x_expand = c(0.05, 0),
  x_padding = c(0.5, 1),
  y_padding = c(0, 0),
  plot_margin = ggplot2::margin(5, 5, 5, 5),
  palette = NULL,
  fill_scale = NULL,
  colour_scale = NULL,
  plot_theme = NULL,
  nest_line_colour = "grey50",
  nest_line_linetype = "dotted",
  nest_line_linewidth = 0.5,
  strip_fill = "white",
  strip_colour = "white",
  strip_text_colour = "black",
  strip_text_face = c("bold", rep("plain", length(nested_cols) - 1)),
  strip_text_size = c(10, rep(6, length(nested_cols) - 1)),
  border_colour = "black",
  border_linewidth = 1
) {

  x_col <- rlang::ensym(x_col)
  y_col <- rlang::ensym(y_col)
  fill_col <- rlang::ensym(fill_col)
  split_col <- rlang::ensym(split_col)

  nested_cols <- rlang::syms(nested_cols)

  if (is.null(fill_label)) {
    fill_label <- rlang::as_name(fill_col)
  }

  if (!is.null(palette) && !is.null(fill_scale)) {
    warning(
      "Both `palette` and `fill_scale` were supplied. ",
      "Using `fill_scale` and ignoring `palette`.",
      call. = FALSE
    )
  }

  applied_fill_scale <- NULL

  if (!is.null(fill_scale)) {
    applied_fill_scale <- fill_scale
  } else if (!is.null(palette)) {
    applied_fill_scale <- ggplot2::scale_fill_manual(
      values = palette,
      name = fill_label
    )
  }

  x_expand_values <- if (!is.null(x_padding)) {
    x_padding
  } else {
    x_expand
  }

  split_levels <- data |>
    dplyr::distinct(!!split_col) |>
    dplyr::pull(!!split_col)

  n_nested <- length(nested_cols)

  strip_fill <- rep(strip_fill, length.out = n_nested)
  strip_colour <- rep(strip_colour, length.out = n_nested)
  strip_text_colour <- rep(strip_text_colour, length.out = n_nested)
  strip_text_face <- rep(strip_text_face, length.out = n_nested)
  strip_text_size <- rep(strip_text_size, length.out = n_nested)

  nested_formula <- stats::as.formula(
    paste(
      ". ~",
      paste(
        purrr::map_chr(nested_cols, rlang::as_name),
        collapse = " + "
      )
    )
  )

  make_one_plot <- function(split_value) {

    data_split <- data |>
      dplyr::filter(!!split_col == split_value)

    p <- ggplot2::ggplot(
      data_split,
      ggplot2::aes(x = !!x_col, y = !!y_col, fill = !!fill_col)
    ) +
      ggplot2::geom_col(width = bar_width)

    if (!is.null(applied_fill_scale)) {
      p <- p + applied_fill_scale
    }

    if (!is.null(colour_scale)) {
      p <- p + colour_scale
    }

    p <- p +
      ggplot2::scale_x_discrete(
        expand = ggplot2::expansion(
          add = x_expand_values
        )
      ) +
      ggh4x::facet_nested(
        nested_formula,
        space = "free_x",
        scales = "free_x",
        remove_labels = FALSE,
        nest_line = ggplot2::element_line(
          colour = nest_line_colour,
          linetype = nest_line_linetype,
          linewidth = nest_line_linewidth
        ),
        solo_line = TRUE,
        strip = ggh4x::strip_nested(
          clip = "off",
          background_x = ggh4x::elem_list_rect(
            fill = strip_fill,
            color = strip_colour,
            linewidth = c(0.8, rep(0.5, n_nested - 1))
          ),
          text_x = ggh4x::elem_list_text(
            color = strip_text_colour,
            face = strip_text_face,
            size = strip_text_size
          ),
          by_layer_x = TRUE
        )
      ) +
      ggplot2::scale_y_continuous(
        limits = y_limits,
        breaks = y_breaks,
        expand = ggplot2::expansion(
          mult = y_padding
        )
      ) +
      ggplot2::theme_bw() +
      ggplot2::theme(
        panel.grid = ggplot2::element_blank(),
        panel.border = ggplot2::element_blank(),
        panel.spacing.x = grid::unit(0.5, "lines"),

        axis.title.x = ggplot2::element_blank(),
        axis.title.y = ggplot2::element_blank(),
        axis.text.y = ggplot2::element_blank(),
        axis.ticks.y = ggplot2::element_blank(),
        axis.line.y = ggplot2::element_blank(),
        axis.ticks.x = ggplot2::element_blank(),

        legend.position = "none",

        plot.title = ggplot2::element_text(
          face = "bold",
          hjust = 0.5,
          size = 12
        ),

        plot.background = ggplot2::element_rect(
          colour = border_colour,
          fill = NA,
          linewidth = border_linewidth
        ),

        plot.margin = plot_margin
      ) +
      ggplot2::labs(
        title = split_value,
        fill = fill_label
      )

    if (!is.null(plot_theme)) {
      p <- p + plot_theme
    }

    p
  }

  split_plots <- purrr::map(split_levels, make_one_plot)

  split_plots_spaced <- list()

  for (i in seq_along(split_plots)) {
    split_plots_spaced[[length(split_plots_spaced) + 1]] <- split_plots[[i]]

    if (i < length(split_plots)) {
      split_plots_spaced[[length(split_plots_spaced) + 1]] <-
        patchwork::plot_spacer()
    }
  }

  if (split_width_mode == "equal") {
    plot_widths <- rep(1, length(split_plots))
  } else if (split_width_mode == "proportional") {

    width_df <- data |>
      dplyr::distinct(
        !!split_col,
        !!!nested_cols,
        !!x_col
      ) |>
      dplyr::count(!!split_col, name = "n_x_groups")

    plot_widths <- width_df$n_x_groups[
      match(split_levels, width_df[[rlang::as_name(split_col)]])
    ]

    plot_widths <- pmax(plot_widths, min_split_width)

  } else {
    stop("`split_width_mode` must be either 'equal' or 'proportional'.")
  }

  split_widths <- as.vector(
    rbind(
      plot_widths,
      c(rep(season_gap, length(plot_widths) - 1), NA)
    )
  )

  split_widths <- split_widths[!is.na(split_widths)]

  main_panel <- patchwork::wrap_plots(
    split_plots_spaced,
    ncol = length(split_plots_spaced),
    widths = split_widths
  )

  axis_data <- data.frame(
    axis_x = 1,
    axis_y = y_limits
  )

  axis_plot <- ggplot2::ggplot(
    axis_data,
    ggplot2::aes(x = .data$axis_x, y = .data$axis_y)
  ) +
    ggplot2::geom_blank() +
    ggplot2::scale_x_continuous(
      breaks = NULL,
      labels = NULL,
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_continuous(
      limits = y_limits,
      breaks = y_breaks,
      expand = ggplot2::expansion(
        mult = y_padding
      )
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      panel.background = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      panel.border = ggplot2::element_blank(),

      axis.title.x = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      axis.line.x = ggplot2::element_blank(),

      axis.title.y = ggplot2::element_text(size = 11),
      axis.text.y = ggplot2::element_text(size = 9),
      axis.ticks.y = ggplot2::element_line(),

      plot.background = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(0, 0, 0, 0)
    ) +
    ggplot2::labs(y = y_label)

  if (!is.null(plot_theme)) {
    axis_plot <- axis_plot + plot_theme
  }

  axis_plot <- axis_plot +
    ggplot2::theme(
      axis.title.x = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      axis.line.x = ggplot2::element_blank()
    )

  legend_source <- ggplot2::ggplot(
    data,
    ggplot2::aes(x = !!x_col, y = !!y_col, fill = !!fill_col)
  ) +
    ggplot2::geom_col()

  if (!is.null(applied_fill_scale)) {
    legend_source <- legend_source + applied_fill_scale
  }

  if (!is.null(colour_scale)) {
    legend_source <- legend_source + colour_scale
  }

  legend_source <- legend_source +
    ggplot2::theme_void() +
    ggplot2::theme(
      legend.position = "right",
      legend.title = ggplot2::element_text(size = 10),
      legend.text = ggplot2::element_text(size = 9)
    ) +
    ggplot2::labs(fill = fill_label)

  if (!is.null(plot_theme)) {
    legend_source <- legend_source + plot_theme
  }

  legend_only <- cowplot::get_legend(legend_source)

  final_plot <- axis_plot + main_panel + patchwork::wrap_elements(legend_only) +
    patchwork::plot_layout(
      widths = layout_widths
    )

  final_plot
}