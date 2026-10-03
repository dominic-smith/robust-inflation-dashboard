# One-time checks for the Figure 2 percentiles and the bias heatmap data.
# Run from compute/analytical/ after run_compute.R, export_artifacts.R and extract_heatmap.R.
suppressPackageStartupMessages({library(dplyr); library(readr)})
IJCB <- "/Users/smith_d/Dropbox (Work)/Research/ExtendingTheRange_IJCB"

# Figure 2: live 1-month percentiles vs the paper's d24m on years BEA has not revised
paper <- readRDS(file.path(IJCB, "data/2_processed/d24m_distribution_DAL_M_1.rds"))
mine  <- readRDS("../data/2_processed/d24m_distribution_DAL_M_1.rds")
j <- inner_join(paper, mine, by = "date", suffix = c(".p", ".m")) |> filter(date < (2019 - 1960) * 12)
for (q in c("p10", "p24", "p50", "p69", "p90"))
  cat(sprintf("Fig 2 %s, 1960-2018: max|diff| = %.2e (n = %d)\n", q,
              max(abs(j[[paste0(q, ".p")]] - j[[paste0(q, ".m")]]), na.rm = TRUE), nrow(j)))

# Bias: the paper's text says near-optimal trims all have sqrt(avg sq. bias) < 0.5pp,
# and the lowest-bias trims are not near-optimal when targeting current trend.
h  <- read_csv("../../artifacts/heatmap_rmse.csv", show_col_types = FALSE) |> filter(group == 4, sample == "long")
dm <- read_csv("../../artifacts/heatmap_dm.csv", show_col_types = FALSE) |> filter(sample == "long")
for (o in c("c_0_37", "f_12_24")) {
  x <- inner_join(h |> filter(target == o), dm |> filter(target == o), by = c("lb", "beta")) |>
    mutate(eq = is.na(p) | p >= 0.05)
  lo <- x[which.min(x$bias), ]
  cat(sprintf("%s: max bias in equivalence set = %.3f; lowest-bias trim %d/%d (bias %.3f) in set: %s\n",
              o, max(x$bias[x$eq]), lo$lb, lo$beta, lo$bias, lo$eq))
}
