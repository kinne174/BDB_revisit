library(ggplot2)

nfl_theme = list(theme(
  panel.background = element_rect(fill = "lightgreen",
                                  colour = "lightgreen"),
  panel.grid.major.x = element_blank(), 
  panel.grid.minor.x = element_blank(),
  axis.text.x = element_blank(),
  axis.ticks = element_blank(),
  axis.title = element_blank()
  ),
geom_vline(
  xintercept = 17.5,
  colour='white',
  linetype='dotdash'
  ), 
geom_vline(
  xintercept = 17.5 + 18 + 1/3, 
  colour='white', 
  linetype='dotdash'
  ),
coord_cartesian(
  xlim=c(0, 53 + 1/3)
  )
)


