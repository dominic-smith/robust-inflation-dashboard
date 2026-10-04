# RMSE of the reference measures and of the best trim, per panel, with the best
# trim's location (RMSE/bias views) and the DM test's own best trim (DM view).
here <- dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(here, "artifacts.R"))
r <- artifact("heatmap_refs.csv"); r$rmse <- r6(r$rmse)
dm <- artifact("heatmap_dm.csv"); b <- dm[is.na(dm$p), c("sample", "target", "lb", "beta")]
names(b)[3:4] <- c("dm_best_lb", "dm_best_beta")
r <- merge(r, b, by = c("sample", "target"), all.x = TRUE)
emit(r[c("group", "sample", "target", "measure", "rmse", "best_lb", "best_beta", "dm_best_lb", "dm_best_beta")])
