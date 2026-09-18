# ggplot equivalent of scheme-inflation.scheme: white background, dotted grey
# gridlines on both axes, small legend inside the plot, medsmall axis labels.

theme_inflation <- function(legend_pos = c(0.02, 0.98)) {
  theme_bw(base_size = 11) +
    theme(
      panel.grid.major = element_line(color = "grey60", linetype = "dotted", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "black", fill = NA, linewidth = 0.4),
      legend.position = "inside",
      legend.position.inside = legend_pos,
      legend.justification = c(0, 1),
      legend.background = element_blank(),
      legend.key = element_blank(),
      legend.text = element_text(size = 8),
      legend.title = element_blank(),
      axis.title = element_blank(),
      plot.subtitle = element_text(size = 9, hjust = 0)
    )
}

# Mirrors the repeated `graph export .png` + `.pdf` pattern (and save_fig.ado)
save_fig <- function(plot, stub, width = 7.5, height = 4.5) {
  ggsave(paste0(stub, ".png"), plot, width = width, height = height, dpi = 150)
  ggsave(paste0(stub, ".pdf"), plot, width = width, height = height)
}

# ~6 date breaks like Stata tlabel(#6); x is integer %tm codes
scale_x_tm <- function(tm_range, n = 6) {
  breaks <- pretty(tm_range, n = n)
  scale_x_continuous(breaks = breaks, labels = tm_label(breaks))
}
