library(ggplot2)

nfl_theme = list(theme(
  panel.background = element_rect(fill = "lightgreen",
                                  colour = "lightgreen"),
  panel.grid.major.x = element_blank(), 
  panel.grid.minor = element_blank(),
  axis.text = element_blank(),
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
  ),
geom_vline(
  xintercept = 0,
  colour = 'white',
  linetype = 'solid',
  size = 2
  ),
geom_vline(
  xintercept = 53 + 1/3,
  colour = 'white',
  linetype = 'solid',
  size = 2
  ),
scale_y_continuous(
  breaks = seq(from=10, to=110, by = 5)),
geom_rect(
  xmin = 0,
  xmax = 53 + 1/3,
  ymin = 0,
  ymax = 10,
  size = 0,
  color = 'lightblue',
  alpha = 0.2
  ),
geom_rect(
  xmin = 0,
  xmax = 53 + 1/3,
  ymin = 110,
  ymax = 120,
  size = 0,
  color = 'blue',
  alpha = 0.05
  )
)


