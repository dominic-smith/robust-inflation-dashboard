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

# Label maps shared across tabs
HORIZON_LEVELS <- c("1m", "3m", "12m")
HORIZON_LABELS <- c(`1m` = "1-month", `3m` = "3-month", `12m` = "12-month")
TARGET_LABELS <- c(c_0_37 = "Current trend", f_0_24 = "Future inflation (0–24m)",
                   f_12_24 = "Future inflation (12–24m)", b_2_39 = "Past average (2–39m)")
SAMPLE_LABELS <- c(long = "Full sample", `80s` = "1980s onward", `00s` = "2000s onward")
GROUP_LABELS  <- c(`4` = "All categories", `5` = "Excluding housing")

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
