# Robustness heatmaps, one row per (category set, sample, trend measure, trim):
#   rel  = RMSE / best trim's RMSE, capped at 2.5
#   bias = sqrt(average squared bias), only where < 0.5pp (as in the paper)
#   pcls = DM test vs best trim: 1 p<0.01, 2 0.01-0.05, 3 0.05-0.10, 4 >=0.10 (best = 4);
#          all-categories set only
h <- artifact("heatmap_rmse.csv")
best <- ave(h$rmse, h$group, h$sample, h$target, FUN = min)
h$rel <- round(pmin(h$rmse / best, 2.5), 6)
h$bias <- ifelse(h$bias < 0.5, round(h$bias, 6), NA)
dm <- artifact("heatmap_dm.csv"); dm$group <- 4
h <- merge(h, dm[c("group", "sample", "target", "lb", "beta", "p")], all.x = TRUE)
p <- ifelse(h$group == 4 & is.na(h$p), 1, h$p)          # the best trim is equivalent to itself
h$pcls <- ifelse(is.na(p), NA, as.integer(cut(p, c(-Inf, 0.01, 0.05, 0.10, Inf), right = FALSE)))
heat_table <- h[order(h$group, h$sample, h$target, h$lb, h$beta), c("group", "sample", "target", "lb", "beta", "rel", "bias", "pcls")]
