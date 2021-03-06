# Data from:
# Johns Hopkins University Center for System Science and Engineering (JHU CCSE)

library(dplyr)
library(tidyr)
library(leaflet)
library(leaflet.extras)
library(shinydashboard)

library(shiny)
library(plotly)
library(shinythemes)


baseURL = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series"

f1 = list(family="Century Gothic, monospace", size=12, color="rgb(30,30,30)")

minutesSinceLastUpdate = function(fileName) {
  (as.numeric(as.POSIXlt(Sys.time())) - as.numeric(file.info(fileName)$ctime)) / 60
}

loadData = function(fileName, columnName) {
  if(!file.exists(fileName) || minutesSinceLastUpdate(fileName) > 10) {
    data = read.csv(file.path(baseURL, fileName), check.names=FALSE, stringsAsFactors=FALSE) %>%
      pivot_longer(-(1:4), names_to="date", values_to=columnName) %>% 
      mutate(
        date=as.Date(date, format="%m/%d/%y"),
        `Country/Region`=if_else(`Country/Region` == "", "?", `Country/Region`),
        `Province/State`=if_else(`Province/State` == "", "<all>", `Province/State`)
      )
    save(data, file=fileName)  
  } else {
    load(file=fileName)
  }
  return(data)
}

loadDataMap = function(fileName) {
  if(!file.exists(fileName) || minutesSinceLastUpdate(fileName) > 10) {
    data = read.csv(file.path(baseURL, fileName), check.names=FALSE, stringsAsFactors=FALSE)
    save(data, file=fileName)  
  } else {
    load(file=fileName)
  }
  return(data)
}

allData = 
  loadData(
    "time_series_covid19_confirmed_global.csv", "CumConfirmed") %>%
  inner_join(loadData(
    "time_series_covid19_deaths_global.csv", "CumDeaths")) %>%
  inner_join(loadData(
    "time_series_covid19_recovered_global.csv","CumRecovered"))

confirmed = loadDataMap("time_series_covid19_confirmed_global.csv")
deaths = loadDataMap("time_series_covid19_deaths_global.csv")
recovered = loadDataMap("time_series_covid19_recovered_global.csv")

function(input, output, session) {
  
  data = reactive({
    d = allData %>%
      filter(`Country/Region` == input$country, as.Date(date) >= as.Date(input$daterange[1]) & as.Date(date) <= as.Date(input$daterange[2]))
    d = d %>% 
    group_by(date) %>% 
    summarise_if(is.numeric, sum, na.rm=TRUE)
    
    d %>%
      mutate(
        dateStr = format(date, format="%b %d, %Y"),    # Jan 20, 2020
        NewConfirmed=CumConfirmed - lag(CumConfirmed, default=0),
        NewRecovered=CumRecovered - lag(CumRecovered, default=0),
        NewDeaths=CumDeaths - lag(CumDeaths, default=0)
      )
  })
  
  mapData = reactive({
    d = allData %>% 
      group_by(`Country/Region`, Lat, Long) %>% 
      summarise_if(is.numeric, sum, na.rm=TRUE)
    
    d = d %>%
      mutate(
        NewConfirmed=CumConfirmed - lag(CumConfirmed, default=0),
        NewRecovered=CumRecovered - lag(CumRecovered, default=0),
        NewDeaths=CumDeaths - lag(CumDeaths, default=0),
        Activos = NewConfirmed - NewRecovered - NewDeaths
      )
    d %>%
      filter(as.numeric(Activos) >= as.numeric(input$cases_range))
  })
  
  observeEvent(input$country, {
    states = allData %>%
      filter(`Country/Region` == input$country) %>% 
      pull(`Province/State`)
    states = c("<all>", sort(unique(states)))
    updateSelectInput(session, "state", choices=states, selected=states[1])
  })
  
  countries = sort(unique(allData$`Country/Region`))
  
  updateSelectInput(session, "country", choices=countries, selected="China")
  
  renderMap = function() {
    renderLeaflet({
      mydata = mapData()
      leaflet(mydata) %>% 
        setView(lng = 0, lat = 45, zoom = 2)  %>% #setting the view over ~ center of North America
        addTiles() %>% 
        addCircles(data = mydata, lat = ~ Lat, lng = ~ Long, weight = 1, radius = ~sqrt(Activos)*90, color = 'orange', fillOpacity = 0.5)
    })
  }
  
  renderBarPlot = function(varPrefix, legendPrefix, yaxisTitle) {
    renderPlotly({
      data = data()
      plt = data %>% 
        plot_ly() %>%
        config(displayModeBar=FALSE) %>%
        layout(
          barmode='group', 
          xaxis=list(
            title="", tickangle=-90, type='category', ticktext=as.list(data$dateStr), 
            tickvals=as.list(data$date), gridwidth=1), 
          yaxis=list(
            title=yaxisTitle
          ),
          legend=list(x=0.05, y=0.95, font=list(size=15), bgcolor='rgba(240,240,240,0.5)'),
          font=f1
        )
      for(metric in input$metrics) 
        plt = plt %>%
          add_trace(
            x= ~date, y=data[[paste0(varPrefix, metric)]], type='bar', 
            name=paste(legendPrefix, metric, "Cases"),
            marker=list(
              color=switch(metric, Deaths='rgb(200,30,30)', Recovered='rgb(30,200,30)', Confirmed='rgb(100,140,240)'),
              line=list(color='rgb(8,48,107)', width=1.0)
            )
          )
      plt
    })
  }
  

  
  confirmed = select(confirmed, -Lat, -Long)
  sumsc = data.frame(colSums(Filter(is.numeric, confirmed)))
  tConfirmed = colSums(sumsc)
  
  deaths = select(deaths, -Lat, -Long)
  sumsd = data.frame(colSums(Filter(is.numeric, deaths)))
  tDeaths = colSums(sumsd)
  
  recovered = select(recovered, -Lat, -Long)
  sumsr = data.frame(colSums(Filter(is.numeric, recovered)))
  tRecovered = colSums(sumsr)
  
  output$dailyMetrics = renderBarPlot("New", legendPrefix="New", yaxisTitle="New Cases per Day")
  output$value1 = renderValueBox({
    valueBox(
      tConfirmed
      ,paste('Confirmados Globalmente'))
    
    
  })
  output$value2 = renderValueBox({
    valueBox(
      formatC(tDeaths, format="d", big.mark=',')
      ,paste('Muertes Globalmente'))
    
    
  })

  output$value3 = renderValueBox({
    valueBox(
      formatC(tRecovered, format="d", big.mark=',')
      ,paste('Recuperados Globalmente')
      )
    
  })
  
  output$cumulatedMetrics = renderBarPlot("Cum", legendPrefix="Cumulated", yaxisTitle="Cumulated Cases")
  output$my_map = renderMap()
}


