# Small helpers replicating Stata semantics that differ from base R.

# Stata round(): half away from zero (R round() is half to even)
stata_round <- function(x, unit = 1) sign(x) * floor(abs(x) / unit + 0.5 + 1e-12) * unit

# Stata gen running sum(): NA treated as 0, never returns NA
stata_sum <- function(x) cumsum(ifelse(is.na(x), 0, x))

# Stata egen total() / collapse (sum): NA treated as 0; all-NA group -> 0
stata_total <- function(x) sum(x, na.rm = TRUE)

# Stata egen max()/min() and collapse (max)/(min): NA on all-NA groups, no warning
stata_max <- function(x) if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE)
stata_min <- function(x) if (all(is.na(x))) NA_real_ else min(x, na.rm = TRUE)

# Stata collapse (mean)/(sd) ignore NA
stata_mean <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
stata_sd   <- function(x) if (sum(!is.na(x)) < 2) NA_real_ else sd(x, na.rm = TRUE)

# Stata display format %4.2f etc., with Stata's rounding of ties
fmt <- function(x, digits = 2) sprintf(paste0("%.", digits, "f"), stata_round(x, 10^(-digits)))

# Stata destring force: non-numeric -> NA without warnings
destring_force <- function(x) suppressWarnings(as.numeric(x))
