# Port of ado/lag_list.ado: lag = 1 for annual, {1,3} for quarterly, {1,3,12} for monthly
lag_list <- function(f) {
  lags <- 1L
  if (f %in% c("Q", "M")) lags <- c(lags, 3L)
  if (f == "M") lags <- c(lags, 12L)
  lags
}
