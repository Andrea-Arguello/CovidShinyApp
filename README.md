# CovidShinyApp (Laboratorio 9 del curso de Data Science 1)
## Descripción
Un dashboard de Shiny que despliega información del Covid-19. Trabajado sobre el trabajo de [Meinhard Ploner](https://github.com/ploner/coronavirus-r) y utilizando información de [este](https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series) repositorio, el cual es actualizado una vez al día a las 23:59 (UTC).

Se considera que este Shiny puede mejorarse en aspectos de estética y de visualización, como el implementar los siguientes cambios (que fue lo que hicimos):
```diff
+ visualización de mapa
+ slider
+ dateRangeInput
- gráfico de frecuencia acumulada (es poco entendible y no se ven cambios significativos en los últimos meses)
- dropdown de 'estado/provincia' (solo servía con información de EEUU)
```
