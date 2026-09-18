# Load PCE Data — translation of 1_cleaning/01m-load_data.do

format_PCE_data <- function(sheet_df, varname) {
  # Stata names cols by row-8 header: Line, B, C, then date labels -> _1959m01 etc.
  df <- sheet_df
  names(df)[1:3] <- c("line", "product_name", "series_id")
  names(df)[-(1:3)] <- tolower(names(df)[-(1:3)])  # "1959M01" -> "1959m01"

  df <- df |>
    pivot_longer(cols = -(1:3), names_to = "period", values_to = varname) |>
    # drop if `varname' == ""  (empty cells; "....." rows are KEPT and become NA)
    filter(!is.na(.data[[varname]]), .data[[varname]] != "") |>
    mutate(line = destring_force(line),
           !!varname := destring_force(.data[[varname]])) |>
    filter(!(line > 340 & line != 374), !is.na(line), !line %in% c(10, 11)) |>
    mutate(line = ifelse(line >= 10, line - 2, line))
  df
}

# import excel cellrange(A8) firstrow: header in row 8, everything read as text
# (Stata gets string columns here too because of "....." cells; destring later)
read_bea_sheet <- function(path, sheet) {
  # trim_ws = FALSE: product_name indentation encodes the PCE hierarchy level
  df <- suppressMessages(
    read_excel(path, sheet = sheet, skip = 7, col_types = "text",
               trim_ws = FALSE, .name_repair = "minimal"))
  df[, names(df) != "" | seq_along(df) <= 3]
}

load_data <- function(freq) {
  bea <- "../data/1_raw/Section2All_xls.xlsx"

  pce_prices   <- format_PCE_data(read_bea_sheet(bea, paste0("U20404-", freq)), "price_index")
  pce_quantity <- format_PCE_data(read_bea_sheet(bea, paste0("U20403-", freq)), "quantity_index")
  pce_spending <- format_PCE_data(read_bea_sheet(bea, paste0("U20406-", freq)), "real_spending")
  weights      <- format_PCE_data(read_bea_sheet(bea, paste0("U20405-", freq)), "weight")

  # merge 1:1 line period, assert(3) for prices/quantity; spending keeps _merge 1|3
  stopifnot(nrow(anti_join(weights, pce_prices, by = c("line", "period"))) == 0,
            nrow(anti_join(pce_prices, weights, by = c("line", "period"))) == 0)
  df <- weights |>
    inner_join(select(pce_prices, line, period, price_index), by = c("line", "period")) |>
    inner_join(select(pce_quantity, line, period, quantity_index), by = c("line", "period")) |>
    left_join(select(pce_spending, line, period, real_spending), by = c("line", "period"))

  write_proc(df, "d01m_loaded_data")
  df
}

load_classification <- function() {
  cd <- read_excel("../data/1_raw/category_definitions.xlsx") |>
    rename_with(tolower) |>
    mutate(line = destring_force(line)) |>
    filter(!is.na(line))

  f <- file.path(GLOBALS$figures, "01m-numbers.tex")
  open_numbers(f)
  write_copy(f, "trim_cats", sum(cd$dallas == "x", na.rm = TRUE))
  write_copy(f, "median_cats", sum(cd$cleveland == "x", na.rm = TRUE))

  write_raw(cd, "category_definitions")
  cd
}

create_level <- function(df) {
  df |> mutate(
    level = nchar(product_name) - nchar(trimws(product_name)),
    level = level + 2,
    level = ifelse(line == 1, 0, level),
    level = level / 2)
}

export_data <- function(df, freq) {
  # total expenditure rows (line == 1), merged back by period
  total <- df |>
    filter(line == 1) |>
    select(period, total = weight, price_level = price_index,
           total_real = real_spending, total_quantity = quantity_index)
  df <- df |>
    left_join(total, by = "period") |>
    mutate(spending = weight)

  # Format date variable ("1959m01" -> 195901; quarterly "1959q1" -> 19591)
  if (freq == "M") df <- df |> mutate(period = as.numeric(paste0(substr(period, 1, 4), substr(period, 6, 7))))
  if (freq == "Q") df <- df |> mutate(period = as.numeric(paste0(substr(period, 1, 4), substr(period, 6, 6))))
  if (freq == "A") df <- df |> mutate(period = as.numeric(period))

  df <- df |>
    mutate(series_id = substr(series_id, 1, 5),
           series_id = case_when(line == 220 ~ "VIDEO", line == 221 ~ "AUDIO", TRUE ~ series_id))

  classification <- read_raw("d01m_classification")  # line, name, series_id, decision
  df <- df |> left_join(select(classification, line, decision), by = "line")

  df <- df |>
    mutate(
      spending = ifelse(line %in% c(334, 335, 336, 337, 147, 272), -spending, spending),
      real_spending = ifelse(line %in% c(334, 335, 336, 337, 147, 272), -real_spending, real_spending),
      spending = ifelse(!is.na(decision) & decision == "0 when missing" & is.na(spending), 0, spending),
      real_spending = ifelse(is.na(real_spending), spending / price_index * 100, real_spending),
      weight = spending / total,
      weight_old = spending / total,
      i = match(line, sort(unique(line))))  # egen i = group(line)

  if (freq == "M") {
    df <- df |>
      mutate(y = floor(period / 100), m = period - y * 100, q = ceiling(m / 3),
             date = tm(y, m)) |>
      arrange(i, date) |>
      group_by(i) |>
      mutate(g_i_12 = price_index / tslag(price_index, date, 12) * 100,
             g_i_3  = price_index / tslag(price_index, date, 3) * 100,
             g_i_1  = price_index / tslag(price_index, date, 1) * 100) |>
      ungroup()
  }
  if (freq == "Q") {
    df <- df |>
      mutate(y = floor(period / 10), q = period - y * 10, date = tq(y, q)) |>
      arrange(i, date) |>
      group_by(i) |>
      mutate(g_i_3 = price_index / tslag(price_index, date, 3) * 100,
             g_i_1 = price_index / tslag(price_index, date, 1) * 100) |>
      ungroup()
  }
  if (freq == "A") {
    df <- df |>
      mutate(y = period, date = y) |>
      arrange(i, date) |>
      group_by(i) |>
      mutate(g_i_1 = price_index / tslag(price_index, date, 1) * 100) |>
      ungroup()
  }

  df <- df |>
    mutate(period = as.numeric(y >= 1990)) |>
    group_by(i) |>
    mutate(g_i = price_index / tslag(price_index, date, 1) * 100,
           infl_reported = price_level / tslag(price_level, date, 1) * 100,
           agg_pce = price_level / tslag(price_level, date, 12) * 100) |>
    ungroup()

  write_proc(df, paste0("d01m_pce_all_top_", freq))
  write_proc(filter(df, line != 1), paste0("d01m_pce_all_", freq))
  invisible(df)
}

load_nyf <- function() {
  ny <- read_excel("../data/1_raw/nyfed.xlsx") |>
    mutate(ddate = as.Date(Date, format = "%d-%b-%Y"),
           mdate = mofd(ddate))
  write_proc(ny, "d01m_nyfed")
}

main_01m <- function() {
  category_definitions <- load_classification()
  for (freq in c("M", "A", "Q")) {
    message("01m: freq ", freq)
    df <- load_data(freq)
    df <- create_level(df)
    # merge m:1 line using category_definitions, keep(3) assert(2 3); drop id
    stopifnot(nrow(anti_join(df, category_definitions, by = "line")) == 0)  # assert no master-only
    df <- df |>
      inner_join(select(category_definitions, -id), by = "line") |>
      export_data(freq)
  }
  load_nyf()
}

main_01m()
