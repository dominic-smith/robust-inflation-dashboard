# Robust Measures of Inflation — public dashboard ---------------------------
# Static shinylive app. All data precomputed by compute/ (BEA -> measures) and
# shipped in app/data/. Tabs: Latest reading, The range, Distribution, Download.

library(shiny)
library(ggplot2)
library(dplyr)
library(readr)

source("R/theme_dashboard.R")

# --- Load precomputed data -------------------------------------------------
series <- read_csv("data/latest_series.csv", show_col_types = FALSE) |>
  mutate(measure = factor(measure, levels = MEASURE_LEVELS))
range_band <- read_csv("data/range_band.csv", show_col_types = FALSE)
distribution <- read_csv("data/distribution.csv", show_col_types = FALSE) |>
  mutate(category = trimws(category))
series_dl <- read_csv("data/series_download.csv", show_col_types = FALSE)

vintage_lines <- readLines("data/vintage.json", warn = FALSE)
grab <- function(key, default = "") {
  m <- regmatches(vintage_lines, regexpr(sprintf('"%s"\\s*:\\s*"[^"]*"', key), vintage_lines))
  if (length(m) == 0) return(default)
  sub(sprintf('.*"%s"\\s*:\\s*"([^"]*)".*', key), "\\1", m[[1]])
}
VINTAGE_LABEL <- grab("vintage_label", "latest")
DIST_LABEL    <- grab("dist_label", VINTAGE_LABEL)
SOURCE_NOTE   <- grab("source", "")

max_date <- max(series$date)
latest_df <- series[series$date == max_date, ]
latest_vals <- setNames(as.list(latest_df$value), as.character(latest_df$measure))

cutoff_for <- function(yrs) {
  if (yrs <= 0) return(min(series$date))
  seq(max_date, length.out = 2, by = sprintf("-%d years", yrs))[2]
}
pct <- function(x) sprintf("%.1f%%", x)

# --- UI --------------------------------------------------------------------
ui <- navbarPage(
  title = "Robust Measures of Inflation",
  id = "nav",
  header = tags$head(tags$style(HTML("
    .value-card {border:1px solid #e6e6e6; border-radius:10px; padding:14px 16px; text-align:center; margin-bottom:12px;}
    .value-card .lbl {font-size:13px; color:#555; margin-bottom:4px;}
    .value-card .val {font-size:30px; font-weight:700; line-height:1;}
    .value-card .sub {font-size:12px; color:#888; margin-top:4px;}
    .foot {color:#777; font-size:12px; margin-top:18px; border-top:1px solid #eee; padding-top:10px;}
    .lead {color:#444; max-width:760px;}
  "))),

  # ---- Tab 1: Latest reading ----
  tabPanel("Latest reading", fluidPage(
    h3("What is inflation now?"),
    p(class = "lead", sprintf("12-month percent change in consumer prices, four ways. Data through %s.", VINTAGE_LABEL)),
    uiOutput("cards"),
    br(),
    sidebarLayout(
      sidebarPanel(width = 3,
        radioButtons("window", "Time window",
          choices = c("Last 3 years" = 3, "Last 5 years" = 5, "Last 10 years" = 10, "Full history" = 0),
          selected = 5),
        checkboxGroupInput("measures", "Measures", choices = MEASURE_LEVELS, selected = MEASURE_LEVELS)),
      mainPanel(width = 9, plotOutput("trend", height = "460px"))
    ),
    div(class = "foot", HTML(sprintf("Source: %s.<br/>Ocampo, Schoenle &amp; Smith, \"Robustness of Robust Measures of Inflation.\" Updated monthly.", SOURCE_NOTE)))
  )),

  # ---- Tab 2: The range ----
  tabPanel("The range", fluidPage(
    h3("How much do the measures disagree?"),
    p(class = "lead", "Robust measures strip out volatile price changes, but no single one is uniquely “correct.” The shaded band is the range spanned by core, median, and the trimmed mean each month — a gauge of how much the choice of measure matters. It widens exactly when inflation is turning."),
    uiOutput("range_cards"),
    br(),
    sidebarLayout(
      sidebarPanel(width = 3,
        radioButtons("rwindow", "Time window",
          choices = c("Last 5 years" = 5, "Last 10 years" = 10, "Since 1990" = 36, "Full history" = 0),
          selected = 10)),
      mainPanel(width = 9, plotOutput("rangeplot", height = "460px"))
    ),
    div(class = "foot", "Band = max minus min of core PCE, median PCE, and the trimmed mean. Line = headline PCE.")
  )),

  # ---- Tab 3: Distribution ----
  tabPanel("Distribution", fluidPage(
    h3(sprintf("What trimming removes — %s", DIST_LABEL)),
    p(class = "lead", "Each detailed PCE category's 12-month price change, weighted by its share of spending. The trimmed mean discards the weighted tails (shaded) and averages what's left; the median is the middle of the distribution. Headline inflation keeps everything — including the extremes."),
    plotOutput("distplot", height = "440px"),
    div(class = "foot", "Grey bars are the categories the trimmed mean discards — the lightest 24% and heaviest 31% of spending weight. A few categories fall outside the plotted range entirely; those extremes are exactly what trimming guards against.")
  )),

  # ---- Tab 4: Download & methods ----
  tabPanel("Download & methods", fluidPage(
    h3("Download the data"),
    p(class = "lead", sprintf("Monthly series for all four measures, 1960–%s, as computed from the current BEA underlying PCE detail.", VINTAGE_LABEL)),
    downloadButton("dl", "Download CSV"),
    br(), br(),
    tableOutput("preview"),
    h4("Methods"),
    p(class = "lead", HTML("Headline and core PCE are BEA aggregates. The median and trimmed mean are computed from the roughly 180 detailed PCE categories: weighting each category's price change by its expenditure share, sorting, and taking the weighted middle (median) or discarding the weighted tails and averaging the rest (trimmed mean). This reproduces the methodology of Ocampo, Schoenle &amp; Smith, applied to the latest data vintage each month.")),
    p(class = "foot", "Because BEA revises historical data, figures here reflect the current vintage and will differ slightly from the frozen numbers in the published paper. This dashboard is a living companion to the paper, not the paper's archival record.")
  ))
)

# --- Server ----------------------------------------------------------------
server <- function(input, output, session) {

  # Tab 1
  output$cards <- renderUI({
    cards <- lapply(MEASURE_LEVELS, function(mz) {
      col <- unname(MEASURE_COLORS[mz])
      column(3, div(class = "value-card",
        div(class = "lbl", mz),
        div(class = "val", style = sprintf("color:%s;", col), pct(latest_vals[[mz]])),
        div(class = "sub", VINTAGE_LABEL)))
    })
    fluidRow(cards)
  })

  output$trend <- renderPlot({
    d <- series |> filter(measure %in% input$measures, date >= cutoff_for(as.numeric(input$window)))
    validate(need(nrow(d) > 0, "Select at least one measure."))
    ggplot(d, aes(date, value, color = measure)) +
      geom_hline(yintercept = 2, linetype = "dashed", color = "#bbbbbb") +
      geom_line(linewidth = 0.9) +
      scale_color_manual(values = MEASURE_COLORS, drop = FALSE) +
      scale_y_continuous(labels = function(x) paste0(x, "%")) +
      labs(y = "12-month % change", caption = "Dashed line: 2% target.") +
      theme_rrm()
  })

  # Tab 2
  output$range_cards <- renderUI({
    avg_all  <- mean(range_band$diff, na.rm = TRUE)
    avg_low  <- mean(range_band$diff[range_band$cat == 0], na.rm = TRUE)
    avg_high <- mean(range_band$diff[range_band$cat == 2], na.rm = TRUE)
    latest_sp <- range_band$diff[which.max(range_band$date)]
    mk <- function(lbl, val) column(3, div(class = "value-card",
      div(class = "lbl", lbl), div(class = "val", sprintf("%.1f", val)),
      div(class = "sub", "pp spread")))
    fluidRow(mk("Latest", latest_sp), mk("Average", avg_all),
             mk("Low-inflation months", avg_low), mk("High-inflation months", avg_high))
  })

  output$rangeplot <- renderPlot({
    yrs <- as.numeric(input$rwindow)
    co <- cutoff_for(yrs)
    b <- range_band |> filter(date >= co)
    hl <- series |> filter(measure == "Headline PCE", date >= co)
    ggplot() +
      geom_ribbon(data = b, aes(date, ymin = lo, ymax = hi), fill = "grey70", alpha = 0.55) +
      geom_line(data = hl, aes(date, value), color = MEASURE_COLORS[["Headline PCE"]], linewidth = 0.9) +
      geom_hline(yintercept = 2, linetype = "dashed", color = "#bbbbbb") +
      scale_y_continuous(labels = function(x) paste0(x, "%")) +
      labs(y = "12-month % change", caption = "Grey band: range of robust measures. Line: headline PCE.") +
      theme_rrm()
  })

  # Tab 3
  output$distplot <- renderPlot({
    d <- distribution |> arrange(rate) |> mutate(cumw = cumsum(weight) / sum(weight))
    lo_cut <- max(d$rate[d$cumw <= 0.24], na.rm = TRUE)
    hi_cut <- min(d$rate[d$cumw >= 0.69], na.rm = TRUE)
    xr <- c(-12, 18)
    # Bin weight into 1pp bins, classify each bin as kept (middle) or trimmed (tail)
    bins <- d |>
      mutate(bin = floor(rate)) |>
      group_by(bin) |>
      summarise(w = sum(weight), .groups = "drop") |>
      mutate(status = ifelse(bin + 0.5 >= lo_cut & bin + 0.5 <= hi_cut, "Kept (averaged)", "Trimmed away"),
             x = bin + 0.5)
    mk_df <- data.frame(
      name = factor(c("Headline (mean)", "Median", "Trimmed mean"),
                    levels = c("Headline (mean)", "Median", "Trimmed mean")),
      value = c(latest_vals[["Headline PCE"]], latest_vals[["Cleveland median"]],
                latest_vals[["Dallas trimmed mean"]]))
    ggplot() +
      geom_col(data = bins, aes(x, w, fill = status), width = 1, color = "white") +
      geom_vline(data = mk_df, aes(xintercept = value, color = name), linewidth = 1) +
      scale_fill_manual(values = c("Kept (averaged)" = "#4C78A8", "Trimmed away" = "#C9CDD2")) +
      scale_color_manual(values = c("Headline (mean)" = "#111111", "Median" = "#D55E00", "Trimmed mean" = "#009E73")) +
      coord_cartesian(xlim = xr) +
      labs(x = "12-month price change by category (%)", y = "Share of spending",
           fill = NULL, color = NULL, caption = "Grey bars: categories the trimmed mean discards.") +
      guides(fill = guide_legend(order = 1), color = guide_legend(order = 2)) +
      theme_rrm()
  })

  # Tab 4
  output$preview <- renderTable({
    tail(series_dl, 12) |>
      mutate(date = format(as.Date(date), "%Y-%m")) |>
      rename(Month = date)
  }, digits = 2)

  output$dl <- downloadHandler(
    filename = function() sprintf("robust_inflation_measures_%s.csv", format(max_date, "%Y-%m")),
    content = function(file) write_csv(series_dl, file)
  )
}

shinyApp(ui, server)
