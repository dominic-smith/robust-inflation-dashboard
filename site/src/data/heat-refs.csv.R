# RMSE of the reference measures and the best trim, per panel, plus the best trim's
# location for the RMSE / bias views (the DM view marks the DM test's own best trim).
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
r <- artifact("heatmap_refs.csv")
r$rmse <- round(r$rmse, 6)
dm <- artifact("heatmap_dm.csv"); b <- dm[is.na(dm$p), c("sample", "target", "lb", "beta")]
names(b)[3:4] <- c("dm_best_lb", "dm_best_beta")
r <- merge(r, b, by = c("sample", "target"), all.x = TRUE)
emit(r[c("group", "sample", "target", "measure", "rmse", "best_lb", "best_beta", "dm_best_lb", "dm_best_beta")])
