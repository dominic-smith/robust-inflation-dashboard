# Robust Measures of Inflation — public dashboard ---------------------------
# Phase 1: "Latest reading" tab. Static shinylive app; all data is precomputed
# by refresh_dashboard.R in the private pipeline repo and shipped in app/data/.
# The navbarPage scaffold is ready for the range / distribution / robustness
# tabs added in later phases.

library(shiny)
library(ggplot2)
library(dplyr)
library(readr)

source("R/theme_dashboard.R")

# --- Load precomputed data at startup --------------------------------------
series <- read_csv("data/latest_series.csv", show_col_types = FALSE) |>
  mutate(measure = factor(measure, levels = MEASURE_LEVELS))

# Read the vintage label without a JSON dependency (webR-friendly).
vintage_lines <- readLines("data/vintage.json", warn = FALSE)
grab <- function(key, default = "") {
  m <- regmatches(vintage_lines, regexpr(sprintf('"%s"\\s*:\\s*"[^"]*"', key), vintage_lines))
  if (length(m) == 0) return(default)
  sub(sprintf('.*"%s"\\s*:\\s*"([^"]*)".*', key), "\\1", m[[1]])
}
VINTAGE_LABEL <- grab("vintage_label", "latest")
SOURCE_NOTE   <- grab("source", "")

max_date <- max(series$date)
min_date <- min(series$date)

# --- UI --------------------------------------------------------------------
ui <- navbarPage(
  title = "Robust Measures of Inflation",
  id = "nav",
  header = tags$head(tags$style(HTML("
    .value-card {border:1px solid #e6e6e6; border-radius:10px; padding:14px 16px; text-align:center;}
    .value-card .lbl {font-size:13px; color:#555; margin-bottom:4px;}
    .value-card .val {font-size:30px; font-weight:700; line-height:1;}
    .value-card .sub {font-size:12px; color:#888; margin-top:4px;}
    .foot {color:#777; font-size:12px; margin-top:18px; border-top:1px solid #eee; padding-top:10px;}
  "))),

  tabPanel(
    "Latest reading",
    fluidPage(
      h3("What is inflation now?"),
      p(sprintf("12-month percent change. Data through %s.", VINTAGE_LABEL)),
      uiOutput("cards"),
      br(),
      sidebarLayout(
        sidebarPanel(
          width = 3,
          radioButtons("window", "Time window",
            choices = c("Last 3 years" = 3, "Last 5 years" = 5,
                        "Last 10 years" = 10, "Full history" = 0),
            selected = 5),
          checkboxGroupInput("measures", "Measures",
            choices = MEASURE_LEVELS, selected = MEASURE_LEVELS)
        ),
        mainPanel(
          width = 9,
          plotOutput("trend", height = "460px")
        )
      ),
      div(class = "foot",
        HTML(sprintf("Source: %s.<br/>From Ocampo, Schoenle &amp; Smith, \"Robustness of Robust Measures of Inflation.\" Updated monthly.", SOURCE_NOTE))
      )
    )
  )
)

# --- Server ----------------------------------------------------------------
server <- function(input, output, session) {

  filtered <- reactive({
    d <- series |> filter(measure %in% input$measures)
    yrs <- as.numeric(input$window)
    if (yrs > 0) {
      cutoff <- seq(max_date, length.out = 2, by = sprintf("-%d years", yrs))[2]
      d <- d |> filter(date >= cutoff)
    }
    d
  })

  output$cards <- renderUI({
    latest <- series |> filter(date == max_date) |> arrange(measure)
    cols <- lapply(seq_len(nrow(latest)), function(i) {
      row <- latest[i, ]
      col <- unname(MEASURE_COLORS[as.character(row$measure)])
      column(3,
        div(class = "value-card",
          div(class = "lbl", as.character(row$measure)),
          div(class = "val", style = sprintf("color:%s;", col),
              sprintf("%.1f%%", row$value)),
          div(class = "sub", VINTAGE_LABEL)
        )
      )
    })
    fluidRow(cols)
  })

  output$trend <- renderPlot({
    d <- filtered()
    validate(need(nrow(d) > 0, "Select at least one measure."))
    ggplot(d, aes(date, value, color = measure)) +
      geom_hline(yintercept = 2, linetype = "dashed", color = "#bbbbbb") +
      geom_line(linewidth = 0.9) +
      scale_color_manual(values = MEASURE_COLORS, drop = FALSE) +
      scale_y_continuous(labels = function(x) paste0(x, "%")) +
      labs(y = "12-month % change",
           caption = "Dashed line: 2% target.") +
      theme_rrm()
  })
}

shinyApp(ui, server)
