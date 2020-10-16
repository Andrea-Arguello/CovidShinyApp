library(shiny)
library(shinythemes)
library(shinydashboard)
library(plotly)

shinyUI(fluidPage(
  tags$head(includeHTML("google-analytics.html")),
  tags$style(
    type='text/css', 
    ".selectize-input { font-family: Century Gothic, monospace; } .selectize-dropdown { font-family: Century Gothic, monospace; }"
  ),
  tags$style(HTML(
    "body { font-family: Century Gothic, monospace; line-height: 1.1; }"
  )),
  navbarPage(
    "Case History of the Coronavirus (COVID-19)",
    theme = shinytheme("flatly"),
    tabPanel("History",
             fluidRow(
               column(
                 4, 
                 selectizeInput("country", label=h5("Country"), choices=NULL, width="100%")
               ),
               
               column(
                 4, 
                 checkboxGroupInput(
                   "metrics", label=h5("Selected Metrics"), 
                   choices=c("Confirmed", "Deaths", "Recovered"), 
                   selected=c("Confirmed", "Deaths", "Recovered"), width="100%")
               ),
               column(
                 4,
                 dateRangeInput(
                   "daterange", "Date range", start = "2020-01-22", end = NULL, min = "2020-01-22",
                   max = format(Sys.Date(), format = "yyyy-mm-dd"), format = "yyyy-mm-dd", startview = "month", weekstart = 0,
                   language = "en", separator = " to ", width = '100%')
               )
             ),
             fluidRow(
               plotlyOutput("dailyMetrics")
             )
    ),
    tabPanel("COVID map",
             dashboardBody(
               sliderInput("cases_range", "Casos activos totales:",
                           min = 100, max = 5000000,
                           value = 0),
               tags$style(type = "text/css", "#my_map {height: calc(100vh - 100px) !important;}"),
               leafletOutput(outputId = "my_map")
             )
    )
  )
))

