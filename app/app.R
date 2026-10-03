# Robust Measures of Inflation — public dashboard ---------------------------
# Static shinylive app. Monthly measures precomputed by compute/ (BEA -> series),
# the robustness explorer from the paper's prediction analysis (paper vintage).
# Tabs: Latest reading, The range, Distribution, Robustness, Download.

library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)

source("R/theme_dashboard.R")

# --- data ------------------------------------------------------------------
series_h <- read_csv("data/series_h.csv", show_col_types = FALSE) |>
  mutate(measure = factor(measure, levels = MEASURE_LEVELS),
         horizon = factor(horizon, levels = HORIZON_LEVELS))
distribution_h <- read_csv("data/distribution_h.csv", show_col_types = FALSE) |>
  mutate(category = trimws(category))
heat <- read_csv("data/heatmap_rmse.csv", show_col_types = FALSE,
                 col_types = "ccciid")
heat_refs <- read_csv("data/heatmap_refs.csv", show_col_types = FALSE)
heat_dm <- read_csv("data/heatmap_dm.csv", show_col_types = FALSE, col_types = "cciid")
band <- read_csv("data/best_trims_band.csv", show_col_types = FALSE)

grabj <- function(file, key, default = "") {
  ln <- readLines(file, warn = FALSE)
  m <- regmatches(ln, regexpr(sprintf('"%s"\\s*:\\s*"[^"]*"', key), ln))
  if (length(m) == 0) return(default)
  sub(sprintf('.*"%s"\\s*:\\s*"([^"]*)".*', key), "\\1", m[[1]])
}
VINTAGE_LABEL <- grabj("data/vintage.json", "vintage_label", "latest")
SOURCE_NOTE   <- grabj("data/vintage.json", "source", "")

pct <- function(x) sprintf("%.1f%%", x)
cutoff_for <- function(d, yrs) if (yrs <= 0) min(d) else seq(max(d), length.out = 2, by = sprintf("-%d years", yrs))[2]
horizon_note <- "1-month and 3-month changes are annualized."

# --- UI --------------------------------------------------------------------
ui <- navbarPage(
  title = "Robust Measures of Inflation", id = "nav",
  header = tagList(
    tags$head(tags$style(HTML("
      .value-card{border:1px solid #e6e6e6;border-radius:10px;padding:14px 16px;text-align:center;margin-bottom:12px;}
      .value-card .lbl{font-size:13px;color:#555;margin-bottom:4px;}
      .value-card .val{font-size:30px;font-weight:700;line-height:1;}
      .value-card .sub{font-size:12px;color:#888;margin-top:4px;}
      .foot{color:#777;font-size:12px;margin-top:18px;border-top:1px solid #eee;padding-top:10px;}
      .lead{color:#444;max-width:780px;}
      .hbar{background:#f5f6f8;border:1px solid #eaecef;border-radius:8px;padding:6px 12px;margin:6px 0 4px;}
      .hbar .shiny-input-radiogroup{display:inline-block;margin-left:8px;}
      .hbar label{font-weight:600;color:#333;}
      table.dataframe td,table.dataframe th{padding:3px 10px;}
    "))),
    div(class = "hbar",
        tags$span("Horizon:"),
        radioButtons("horizon", NULL, inline = TRUE,
                     choiceNames = unname(HORIZON_LABELS), choiceValues = HORIZON_LEVELS,
                     selected = "12m"))
  ),

  tabPanel("Latest reading", fluidPage(
    h3("What is inflation now?"),
    p(class = "lead", sprintf("Consumer price inflation, four ways. Data through %s. %s", VINTAGE_LABEL, horizon_note)),
    uiOutput("cards"), br(),
    sidebarLayout(
      sidebarPanel(width = 3,
        radioButtons("window", "Time window",
          c("Last 3 years" = 3, "Last 5 years" = 5, "Last 10 years" = 10, "Full history" = 0), selected = 5),
        checkboxGroupInput("measures", "Measures", MEASURE_LEVELS, selected = MEASURE_LEVELS)),
      mainPanel(width = 9, plotOutput("trend", height = "460px"))),
    div(class = "foot", HTML(sprintf("Source: %s. Ocampo, Schoenle &amp; Smith, \"Robustness of Robust Measures of Inflation.\"", SOURCE_NOTE)))
  )),

  tabPanel("Best-trims range", fluidPage(
    h3("What range of trend inflation do the best trims support?"),
    p(class = "lead", "Many trimmed means track trend inflation about equally well: their errors are statistically indistinguishable from the single best trim (Diebold–Mariano test, 5% level). Rather than one number, the shaded band shows the 12-month inflation rates that whole set of near-optimal trims produces each month. This is the paper's Figure 1, updated monthly."),
    uiOutput("bt_cards"), br(),
    sidebarLayout(
      sidebarPanel(width = 3,
        radioButtons("bt_target", "Trend measure the trims are chosen to track",
          choices = setNames(names(TARGET_LABELS), TARGET_LABELS), selected = "c_0_37"),
        radioButtons("bt_sample", "Sample used to choose the trims",
          choices = setNames(names(SAMPLE_LABELS), SAMPLE_LABELS), selected = "long"),
        radioButtons("bt_window", "Time window",
          c("2020 onward (as in Figure 1)" = "2020", "Last 10 years" = "10", "Full history" = "0"),
          selected = "2020")),
      mainPanel(width = 9, plotOutput("bt_plot", height = "460px"))),
    div(class = "foot", "Which trims are statistically equivalent is fixed from the paper's evaluation; each trim is recomputed on every month's data. Band and lines are 12-month changes; the horizon setting does not apply on this tab.")
  )),

  tabPanel("Measure disagreement", fluidPage(
    h3("How much do the measures disagree?"),
    p(class = "lead", "The shaded band is the range spanned by core, median, and the trimmed mean each month — a gauge of how much the choice of measure matters. It widens when inflation is turning."),
    uiOutput("range_cards"), br(),
    sidebarLayout(
      sidebarPanel(width = 3,
        radioButtons("rwindow", "Time window",
          c("Last 5 years" = 5, "Last 10 years" = 10, "Full history" = 0), selected = 10)),
      mainPanel(width = 9, plotOutput("rangeplot", height = "460px"))),
    div(class = "foot", "Band = max minus min of core PCE, median PCE, and the trimmed mean. Line = headline PCE.")
  )),

  tabPanel("Distribution", fluidPage(
    uiOutput("dist_title"),
    p(class = "lead", "Each detailed PCE category's price change, weighted by its share of spending. The trimmed mean discards the weighted tails (grey) and averages the rest; the median is the middle. Headline keeps everything."),
    plotOutput("distplot", height = "420px"),
    h4("What the trimmed mean discards"),
    p(class = "lead", "The categories in the trimmed tails this month, largest weight first."),
    fluidRow(column(6, h5("Cheapest (low tail)"), tableOutput("disc_low")),
             column(6, h5("Most expensive (high tail)"), tableOutput("disc_high"))),
    div(class = "foot", "Grey bars / listed categories are what the trimmed mean removes: the lightest 24% and heaviest 31% of spending weight.")
  )),

  tabPanel("Robustness", fluidPage(
    h3("Which trims best track trend inflation?"),
    p(class = "lead", "Every point is a trimmed mean defined by how much it cuts from the low end (α) and the high end (β). Colour is its error in tracking a chosen measure of trend inflation, relative to the single best trim (dark = better). The broad dark basin is the paper's key finding: a wide range of trims does about equally well — the trimmed mean is robust. Switch to “Statistical equivalence” to see which trims cannot be distinguished from the best; that set defines the band on the Best-trims range tab."),
    sidebarLayout(
      sidebarPanel(width = 3,
        radioButtons("hm_target", "Trend measure", choices = setNames(names(TARGET_LABELS), TARGET_LABELS), selected = "c_0_37"),
        radioButtons("hm_sample", "Sample", choices = setNames(names(SAMPLE_LABELS), SAMPLE_LABELS), selected = "long"),
        radioButtons("hm_group", "Categories", choices = setNames(names(GROUP_LABELS), GROUP_LABELS), selected = "4"),
        radioButtons("hm_view", "Show",
          c("Error relative to best trim" = "rmse", "Statistical equivalence (DM test)" = "dm"), selected = "rmse"),
        br(), tableOutput("hm_refs")),
      mainPanel(width = 9, plotOutput("heatmap", height = "560px"))),
    div(class = "foot", "From the paper's evaluation of every trim against each trend measure over the chosen sample (fixed at the paper's data vintage), not the live monthly series. RMSE = root mean squared error vs the trend measure.")
  )),

  tabPanel("Download & methods", fluidPage(
    h3("Download the data"),
    p(class = "lead", sprintf("Monthly series for all four measures at the selected horizon (%s), through %s.", "1m/3m/12m", VINTAGE_LABEL)),
    downloadButton("dl", "Download CSV (current horizon)"),
    br(), br(), tableOutput("preview"),
    h4("Methods"),
    p(class = "lead", HTML("Headline and core PCE are BEA aggregates. The median and trimmed mean are computed from the ~180 detailed PCE categories — weighting each category's price change by spending share, then taking the weighted middle (median) or discarding the weighted tails and averaging the rest (trimmed mean) — reproducing the methodology of Ocampo, Schoenle &amp; Smith on the latest data vintage. 1- and 3-month changes are annualized.")),
    p(class = "foot", "BEA revises history, so figures reflect the current vintage and differ slightly from the frozen published paper. A living companion to the paper, not its archival record.")
  ))
)

# --- server ----------------------------------------------------------------
server <- function(input, output, session) {

  sh <- reactive(series_h |> filter(horizon == input$horizon))
  dist <- reactive({
    d <- distribution_h |> filter(horizon == input$horizon) |> arrange(rate) |>
      mutate(cumw = cumsum(weight) / sum(weight))
    d$lo_cut <- max(d$rate[d$cumw <= 0.24], na.rm = TRUE)
    d$hi_cut <- min(d$rate[d$cumw >= 0.69], na.rm = TRUE)
    d
  })
  latest_vals <- reactive({
    d <- sh(); md <- max(d$date); x <- d[d$date == md, ]
    setNames(as.list(x$value), as.character(x$measure))
  })

  # Tab 1
  output$cards <- renderUI({
    lv <- latest_vals(); md <- max(sh()$date)
    fluidRow(lapply(MEASURE_LEVELS, function(mz) column(3, div(class = "value-card",
      div(class = "lbl", mz),
      div(class = "val", style = sprintf("color:%s;", unname(MEASURE_COLORS[mz])),
          if (is.null(lv[[mz]])) "–" else pct(lv[[mz]])),
      div(class = "sub", format(md, "%b %Y"))))))
  })
  output$trend <- renderPlot({
    d <- sh() |> filter(measure %in% input$measures, date >= cutoff_for(sh()$date, as.numeric(input$window)))
    validate(need(nrow(d) > 0, "Select at least one measure."))
    ggplot(d, aes(date, value, color = measure)) +
      geom_hline(yintercept = 2, linetype = "dashed", color = "#bbbbbb") +
      geom_line(linewidth = 0.9) +
      scale_color_manual(values = MEASURE_COLORS, drop = FALSE) +
      scale_y_continuous(labels = function(x) paste0(x, "%")) +
      labs(y = sprintf("%s change%s", HORIZON_LABELS[[input$horizon]],
                       if (input$horizon == "12m") "" else ", annualized"),
           caption = "Dashed line: 2% target.") +
      theme_rrm()
  })

  # Tab 2 — range from the three robust measures at the current horizon
  rband <- reactive({
    sh() |> filter(measure %in% c("Core PCE", "Cleveland median", "Dallas trimmed mean")) |>
      group_by(date) |> summarise(lo = min(value), hi = max(value), .groups = "drop") |>
      mutate(diff = hi - lo)
  })
  output$range_cards <- renderUI({
    b <- rband(); hl <- sh() |> filter(measure == "Headline PCE") |> select(date, h = value)
    b <- left_join(b, hl, by = "date")
    f <- function(v) if (all(is.na(v))) "–" else sprintf("%.1f", mean(v, na.rm = TRUE))
    mk <- function(l, v) column(3, div(class = "value-card", div(class = "lbl", l),
      div(class = "val", v), div(class = "sub", "pp spread")))
    fluidRow(
      mk("Latest", sprintf("%.1f", b$diff[which.max(b$date)])),
      mk("Average", f(b$diff)),
      mk("Low inflation (<2.5%)", f(b$diff[b$h < 2.5])),
      mk("High inflation (≥5%)", f(b$diff[b$h >= 5])))
  })
  output$rangeplot <- renderPlot({
    co <- cutoff_for(sh()$date, as.numeric(input$rwindow))
    b <- rband() |> filter(date >= co)
    hl <- sh() |> filter(measure == "Headline PCE", date >= co)
    ggplot() +
      geom_ribbon(data = b, aes(date, ymin = lo, ymax = hi), fill = "grey70", alpha = 0.55) +
      geom_line(data = hl, aes(date, value), color = MEASURE_COLORS[["Headline PCE"]], linewidth = 0.9) +
      geom_hline(yintercept = 2, linetype = "dashed", color = "#bbbbbb") +
      scale_y_continuous(labels = function(x) paste0(x, "%")) +
      labs(y = sprintf("%s change%s", HORIZON_LABELS[[input$horizon]],
                       if (input$horizon == "12m") "" else ", annualized")) +
      theme_rrm()
  })

  # Tab 3
  output$dist_title <- renderUI({
    md <- distribution_h$month[distribution_h$horizon == input$horizon][1]
    h3(sprintf("What trimming removes — %s (%s)", format(as.Date(md), "%B %Y"), HORIZON_LABELS[[input$horizon]]))
  })
  output$distplot <- renderPlot({
    d <- dist(); lo_cut <- d$lo_cut[1]; hi_cut <- d$hi_cut[1]; xr <- c(-12, 18)
    bins <- d |> mutate(bin = floor(rate)) |> group_by(bin) |>
      summarise(w = sum(weight), .groups = "drop") |>
      mutate(status = ifelse(bin + 0.5 >= lo_cut & bin + 0.5 <= hi_cut, "Kept (averaged)", "Trimmed away"), x = bin + 0.5)
    lv <- latest_vals()
    mk_df <- data.frame(name = factor(c("Headline (mean)", "Median", "Trimmed mean"),
                          levels = c("Headline (mean)", "Median", "Trimmed mean")),
      value = c(lv[["Headline PCE"]], lv[["Cleveland median"]], lv[["Dallas trimmed mean"]]))
    ggplot() +
      geom_col(data = bins, aes(x, w, fill = status), width = 1, color = "white") +
      geom_vline(data = mk_df, aes(xintercept = value, color = name), linewidth = 1) +
      scale_fill_manual(values = c("Kept (averaged)" = "#4C78A8", "Trimmed away" = "#C9CDD2")) +
      scale_color_manual(values = c("Headline (mean)" = "#111111", "Median" = "#D55E00", "Trimmed mean" = "#009E73")) +
      coord_cartesian(xlim = xr) +
      labs(x = sprintf("%s price change by category (%%)%s", HORIZON_LABELS[[input$horizon]],
                       if (input$horizon == "12m") "" else ", annualized"),
           y = "Share of spending", fill = NULL, color = NULL) +
      guides(fill = guide_legend(order = 1), color = guide_legend(order = 2)) + theme_rrm()
  })
  disc_tbl <- function(high) {
    d <- dist()
    tail <- if (high) d[d$rate > d$hi_cut[1], ] else d[d$rate < d$lo_cut[1], ]
    tail |> arrange(desc(weight)) |> head(8) |>
      transmute(Category = category, `Change` = sprintf("%+.1f%%", rate),
                `Weight` = sprintf("%.1f%%", weight * 100))
  }
  output$disc_low  <- renderTable(disc_tbl(FALSE), striped = TRUE, width = "100%")
  output$disc_high <- renderTable(disc_tbl(TRUE),  striped = TRUE, width = "100%")

  # Best-trims range (paper Figure 1, live)
  bsel <- reactive(band |> filter(target == input$bt_target, sample == input$bt_sample))
  output$bt_cards <- renderUI({
    b <- bsel(); last <- b[which.max(b$date), ]
    tm12 <- series_h |> filter(horizon == "12m", measure == "Dallas trimmed mean", date == last$date)
    mk <- function(l, v, s) column(3, div(class = "value-card", div(class = "lbl", l),
      div(class = "val", v), div(class = "sub", s)))
    fluidRow(
      mk("Best-trims range", sprintf("%.1f–%.1f%%", last$lo, last$hi), format(last$date, "%b %Y")),
      mk("Set mean", pct(last$mean), "average of the trims"),
      mk("Trimmed mean (24/69)", if (nrow(tm12)) pct(tm12$value) else "–", format(last$date, "%b %Y")),
      mk("Trims in the set", as.character(last$n_trims), sprintf("of 2,601 (%s)", SAMPLE_LABELS[[input$bt_sample]])))
  })
  output$bt_plot <- renderPlot({
    co <- switch(input$bt_window, `2020` = as.Date("2020-01-01"), `10` = cutoff_for(bsel()$date, 10), min(bsel()$date))
    b <- bsel() |> filter(date >= co)
    ln <- series_h |> filter(horizon == "12m", date >= co,
                             measure %in% c("Headline PCE", "Cleveland median", "Dallas trimmed mean")) |>
      mutate(measure = factor(as.character(measure), levels = c("Headline PCE", "Cleveland median", "Dallas trimmed mean")))
    ggplot() +
      geom_ribbon(data = b, aes(date, ymin = lo, ymax = hi, fill = "Range across best trims"), alpha = 0.6) +
      geom_line(data = b, aes(date, mean, linetype = "Set mean"), color = "grey20", linewidth = 0.7) +
      geom_line(data = ln, aes(date, value, color = measure), linewidth = 0.9) +
      geom_hline(yintercept = 2, linetype = "dashed", color = "#bbbbbb") +
      scale_fill_manual(values = c("Range across best trims" = "grey72"), name = NULL) +
      scale_linetype_manual(values = c("Set mean" = "solid"), name = NULL) +
      scale_color_manual(values = MEASURE_COLORS[c("Headline PCE", "Cleveland median", "Dallas trimmed mean")], name = NULL) +
      scale_y_continuous(labels = function(x) paste0(x, "%")) +
      guides(fill = guide_legend(order = 1), linetype = guide_legend(order = 2), color = guide_legend(order = 3)) +
      labs(y = "12-month change", caption = "Dashed line: 2% target.") +
      theme_rrm() + theme(legend.box = "vertical", legend.spacing.y = grid::unit(2, "pt"))
  })

  # Tab 4 — robustness heatmap
  hm_panel <- reactive(heat |> filter(group == input$hm_group, sample == input$hm_sample, target == input$hm_target))
  output$heatmap <- renderPlot({
    refs <- heat_refs |> filter(group == input$hm_group, sample == input$hm_sample, target == input$hm_target)
    if (input$hm_view == "dm") {
      validate(need(input$hm_group == "4", "Equivalence tests were run for the all-categories set only. Switch Categories to “All categories”."))
      d <- heat_dm |> filter(sample == input$hm_sample, target == input$hm_target)
      bl <- d$lb[is.na(d$p)][1]; bb <- d$beta[is.na(d$p)][1]      # the best trim has p = NA
      d$p[is.na(d$p)] <- 1                                         # ...and is trivially equivalent to itself
      d$cls <- cut(d$p, c(-Inf, 0.01, 0.05, 0.10, Inf), right = FALSE,
                   labels = c("p < 0.01", "0.01–0.05", "0.05–0.10 (equivalent)", "≥ 0.10 (equivalent)"))
      fill_layer <- list(geom_raster(aes(fill = cls)),
        scale_fill_manual(values = c("#F4F1E4", "#C6DBEF", "#6BAED6", "#08519C"), na.value = "#08519C",
                          drop = FALSE, name = "DM test vs\nbest trim"))
    } else {
      d <- hm_panel(); best <- min(d$rmse, na.rm = TRUE)
      d$rel <- pmin(d$rmse / best, 2.5)
      bl <- refs$best_lb[1]; bb <- refs$best_beta[1]
      fill_layer <- list(geom_raster(aes(fill = rel)),
        scale_fill_viridis_c(option = "viridis", direction = 1, limits = c(1, 2.5),
                             breaks = c(1, 1.5, 2, 2.5), labels = c("best", "1.5×", "2×", "≥2.5×"), name = "RMSE\nvs best"))
    }
    mcol <- if (input$hm_view == "dm") "grey15" else "white"   # visible on either background
    marks <- data.frame(
      lb = c(0, 24, 50, 8, bl), beta = c(0, 31, 50, 8, bb),
      label = factor(c("Headline", "Trimmed PCE", "Median", "Trimmed CPI", "Best trim"),
                     levels = c("Headline", "Trimmed PCE", "Median", "Trimmed CPI", "Best trim")))
    ggplot(d, aes(lb, beta)) +
      fill_layer +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey85") +
      geom_point(data = marks[marks$label != "Best trim", ], aes(lb, beta, shape = label), color = mcol, size = 2.6, stroke = 1.1) +
      geom_point(data = marks[marks$label == "Best trim", ], aes(lb, beta), shape = 42, color = "#FFD700", size = 12) +
      scale_shape_manual(values = c(Headline = 21, `Trimmed PCE` = 23, Median = 22, `Trimmed CPI` = 24), name = NULL) +
      coord_fixed(xlim = c(0, 50), ylim = c(0, 50), expand = FALSE) +
      labs(x = "Lower trim α (%)", y = "Upper trim β (%)") +
      guides(fill = if (input$hm_view == "dm") guide_legend(nrow = 2, order = 1) else guide_colorbar(order = 1),
             shape = guide_legend(order = 2, override.aes = list(color = "grey15"))) +
      theme_rrm() + theme(panel.grid = element_blank(), legend.box = "vertical")
  })
  output$hm_refs <- renderTable({
    refs <- heat_refs |> filter(group == input$hm_group, sample == input$hm_sample, target == input$hm_target)
    ord <- c("Headline PCE", "Core PCE", "Median PCE", "Trimmed mean", "NY Fed UIG", "Best trim")
    refs |> mutate(measure = factor(measure, levels = ord)) |> arrange(measure) |>
      transmute(Measure = as.character(measure), RMSE = sprintf("%.2f", rmse))
  }, striped = TRUE, width = "100%")

  # Tab 5
  output$preview <- renderTable({
    d <- sh() |> select(date, measure, value) |>
      tidyr::pivot_wider(names_from = measure, values_from = value)
    d |> arrange(date) |> tail(12) |> mutate(date = format(date, "%Y-%m")) |> rename(Month = date)
  }, digits = 2)
  output$dl <- downloadHandler(
    filename = function() sprintf("robust_inflation_%s_%s.csv", input$horizon, format(max(sh()$date), "%Y-%m")),
    content = function(file) {
      d <- sh() |> select(date, measure, value) |> tidyr::pivot_wider(names_from = measure, values_from = value)
      write_csv(arrange(d, date), file)
    })
}

shinyApp(ui, server)
