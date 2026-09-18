# Cleaning: PCE hierarchy and series groups — translation of 1_cleaning/02m-clean_pce.do

# Assign each line its parent: walk rows in line order, tracking the most recent
# line seen at each hierarchy level; the parent is the latest line one level up.
generate_parents <- function(df) {
  parent_at_level <- rep(df$line[1], 9)  # parent_0 .. parent_8 init to line[1]
  parent_id <- rep(NA_real_, nrow(df))
  for (i in 2:nrow(df)) {
    levelup <- df$level[i] - 1
    parent_id[i] <- parent_at_level[levelup + 1]
    parent_at_level[df$level[i] + 1] <- df$line[i]
  }
  df$parent_id <- parent_id
  df
}

create_hierarchy <- function() {
  h <- read_proc("d01m_pce_all_top_A") |>
    arrange(line) |>
    distinct(line, .keep_all = TRUE) |>
    select(line, product_name, series_id, level) |>
    generate_parents()
  write_proc(h, "d02m_pce_hierarchy")
}

# Group 1 is goods and services
group1 <- function() {
  read_proc("d01m_pce_all_top_A") |>
    filter(level == 1) |> distinct(line) |>
    write_proc("d02m_group1")
}

# Group 2 is one level past goods and services with one line indented too much
group2 <- function() {
  read_proc("d01m_pce_all_top_A") |>
    filter(level == 2 | line == 338) |> distinct(line) |>
    write_proc("d02m_group2")
}

# Group 3 is the most detailed set of codes that add up to 100% in a year
group3 <- function() {
  df <- read_proc("d01m_pce_all_top_A") |>
    left_join(select(read_proc("d02m_pce_hierarchy"), line, parent_id), by = "line") |>
    mutate(missing = is.na(price_index) | is.na(spending)) |>
    group_by(parent_id, date) |>
    mutate(child_missing = max(missing)) |>
    ungroup() |>
    # Tobacco (139) should not get dropped because 143 is missing
    filter(!(child_missing == 1 & line != 139))

  parents <- df |> distinct(parent_id, date) |> rename(line = parent_id)
  write_proc(parents, "d02m_parents_group_3")

  # keep series that are not parents at that date; line 276 dropped
  # ("Other services" comment in the .do notwithstanding, the code drops it)
  df <- df |>
    anti_join(parents, by = c("line", "date")) |>
    filter(line != 276) |>
    left_join(select(read_proc("d02m_parent_spending"), line, date, parent_spending),
              by = c("line", "date")) |>
    group_by(date) |>
    mutate(tot = stata_total(spending), weight = spending / tot) |>
    ungroup()

  write_proc(df, "d02m_group3")
}

# Group 4 is a time consistent set of codes
group4 <- function() {
  g4 <- read_proc("d02m_group3") |>
    filter(y == 1959) |>
    distinct(line) |>
    mutate(id = row_number()) |>
    filter(line <= 340, line != 278)

  f <- file.path(GLOBALS$figures, "02m-numbers.tex")
  open_numbers(f)
  write_copy(f, "ss_cats", nrow(g4), comment = "group4")

  write_proc(g4, "d02m_group4")
}

# Group 5 is group 4 without the most important series by weight (Housing)
group5 <- function() {
  g5 <- read_proc("d02m_group4") |> filter(!(line >= 151 & line <= 162))
  f <- file.path(GLOBALS$figures, "02m-numbers.tex")
  write_copy(f, "ss_cats_nohousing", nrow(g5), comment = "group5")
  write_proc(g5, "d02m_group5")
}

group11 <- function() {  # Cleveland
  read_proc("d01m_pce_all_top_A") |>
    filter(cleveland == "x") |> distinct(line) |>
    write_proc("d02m_groupCLE")
}

group12 <- function() {  # Dallas
  read_proc("d01m_pce_all_top_A") |>
    filter(dallas == "x") |> distinct(line) |>
    write_proc("d02m_groupDAL")
}

group13 <- function() {
  read_proc("d02m_group4") |> filter(!(line >= 36 & line <= 59)) |>
    write_proc("d02m_group13")
}

group14 <- function() {
  read_proc("d02m_group4") |> filter(!(line >= 102 & line <= 110)) |>
    write_proc("d02m_group14")
}

group15 <- function() {
  read_proc("d02m_group4") |> filter(!(line >= 111 & line <= 117)) |>
    write_proc("d02m_group15")
}

classify_series <- function() {
  group1(); group2(); group3(); group4(); group5()
  # group6-10 commented out in the .do file
  group11(); group12(); group13(); group14(); group15()
}

# Spending of each line's parent, by date
parent_weights <- function() {
  read_proc("d01m_pce_all_top_A") |>
    select(parent_id = line, parent_spending = spending, date) |>
    inner_join(select(read_proc("d02m_pce_hierarchy"), line, parent_id),
               by = "parent_id", relationship = "many-to-many") |>
    select(line, parent_id, parent_spending, date) |>
    write_proc("d02m_parent_spending")
}

main_02m <- function() {
  create_hierarchy()
  parent_weights()
  classify_series()
}

main_02m()
