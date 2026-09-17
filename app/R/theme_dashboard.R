# Shared look-and-feel for the dashboard ------------------------------------
# Colorblind-safe (Okabe-Ito) palette. Headline PCE is muted grey (context);
# the robust measures get the saturated hues, with the Dallas trimmed mean in
# green as the paper's protagonist.

MEASURE_LEVELS <- c("Headline PCE", "Core PCE", "Cleveland median", "Dallas trimmed mean")

MEASURE_COLORS <- c(
  "Headline PCE"        = "#7F7F7F",  # muted grey
  "Core PCE"            = "#0072B2",  # blue
  "Cleveland median"    = "#D55E00",  # vermillion
  "Dallas trimmed mean" = "#009E73"   # bluish green
)

theme_rrm <- function(base_size = 14) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      axis.title.x     = ggplot2::element_blank(),
      legend.position  = "top",
      legend.title     = ggplot2::element_blank(),
      plot.title       = ggplot2::element_text(face = "bold"),
      plot.caption     = ggplot2::element_text(color = "#666666", hjust = 0)
    )
}
