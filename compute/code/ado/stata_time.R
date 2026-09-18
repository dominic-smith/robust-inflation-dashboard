# Stata %tm month codes (integer months since 1960m1) are kept as the `date`
# variable throughout the pipeline, exactly as in the Stata code. Convert to
# Date class only at plotting time.

tm <- function(y, m) (y - 1960L) * 12L + (m - 1L)          # Stata ym(y, m)
tq <- function(y, q) (y - 1960L) * 4L  + (q - 1L)          # Stata yq(y, q)
tm_year  <- function(tm) 1960L + tm %/% 12L                # Stata year(dofm(tm))
tm_month <- function(tm) tm %% 12L + 1L                    # Stata month(dofm(tm))
tm_to_date <- function(tm) as.Date(sprintf("%d-%02d-01", tm_year(tm), tm_month(tm)))
tm_label <- function(tm) sprintf("%dm%d", tm_year(tm), tm_month(tm))
mofd <- function(d) (as.integer(format(d, "%Y")) - 1960L) * 12L + as.integer(format(d, "%m")) - 1L

# Calendar-based lag, mirroring Stata's l<k>.x under (xt|ts)set: value at date - k,
# NA when that date is absent. Positional dplyr::lag would silently differ across gaps.
tslag <- function(x, date, k = 1) x[match(date - k, date)]
tslead <- function(x, date, k = 1) x[match(date + k, date)]
