# team coverage

source('C:/Users/Mitch/PycharmProjects/BDB_revisit/nfl_theme.R')
source('C:/Users/Mitch/PycharmProjects/BDB_revisit/load_files_helper_functions.R')

library(dplyr)
library(ggplot2)
library(ggforce)

# give specific gameId and playId
my_gameId = 2017091101
my_playId = 740

# load in individual coverages
individual_coverage_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/individualCoverage.csv'
individual_coverage = read_csv(individual_coverage_filename, col_types = cols())

# load in player information for names
players_filename = 'C:/Users/Mitch/Documents/UofM/Fall 2018/NFL/Data/players.csv'
players = read_csv(players_filename)

routes_filename = paste('C:/Users/Mitch/Documents/UofM/Fall 2018/NFL/Data/Routes_', my_gameId ,'.csv', sep = '')
routes = read_csv(routes_filename)
current_routes = routes[which(routes$playId == my_playId),]

# load in same lineStrings as individual_coverage_active_learning.R
# will just work with defense coverage guys and route runners
# on each picture I want name and position of defenders, name, position and route of offensive players, 
# maybe in white boxes to not be as cluttered

lineStrings_lookups = load_both_lookups_lineStrings_helper(gameId = my_gameId, include_ball=T)
current_game_offense_lineStrings = lineStrings_lookups[[1]]
current_game_defense_lineStrings = lineStrings_lookups[[2]]
current_game_ball_lineStrings = lineStrings_lookups[[3]]
current_game_offense_lookup = lineStrings_lookups[[4]]
current_game_defense_lookup = lineStrings_lookups[[5]]

# parse datasets using dplyr to make sure only looking at current play
current_game_defense_lookup = current_game_defense_lookup %>%
  filter(playId == my_playId)

current_game_defense_lineStrings = current_game_defense_lineStrings %>%
  rowwise() %>%
  mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
  mutate(nflId_ = as.numeric(substr(uniqueId, gregexpr('-', uniqueId)[[1]][2] + 1, nchar(uniqueId)))) %>%
  filter(playId_ == my_playId) %>%
  mutate(playId_ = NULL) %>%
  mutate(side = 'defense') %>%
  mutate(position = current_game_defense_lookup$position[current_game_defense_lookup$nflId == nflId_])

current_game_offense_lookup = current_game_offense_lookup %>%
  filter(playId == my_playId)

current_game_offense_lineStrings = current_game_offense_lineStrings %>%
  rowwise() %>%
  mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
  mutate(nflId_ = as.numeric(substr(uniqueId, gregexpr('-', uniqueId)[[1]][2] + 1, nchar(uniqueId)))) %>%
  filter(playId_ == my_playId) %>%
  mutate(playId_ = NULL) %>%
  mutate(side = 'offense') %>%
  mutate(position = current_game_offense_lookup$position[current_game_offense_lookup$nflId == nflId_])
  # mutate(nflId_ = '') %>%
  # mutate(individualCoverage = '')

current_game_ball_lineStrings = current_game_ball_lineStrings %>%
  rowwise() %>%
  mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
  filter(playId_ == my_playId) %>%
  mutate(playId_ = NULL) %>%
  # mutate(nflId_ = '') %>%
  mutate(side = 'ball') %>%
  mutate(position = '')
  # mutate(individualCoverage = '')
  
individual_coverage = individual_coverage %>%
  filter(gameId == my_gameId) %>%
  filter(playId == my_playId)

# calculate the line of scrimmage
los = current_game_ball_lineStrings$x[1]

# get rows of defensive players in zone coverage in individual_coverage
zone_rows = which(individual_coverage$zone, arr.ind = TRUE)
zone_nflIds = individual_coverage$nflId[zone_rows]
zone_positions = individual_coverage$position[zone_rows]

# classify if they are deep/ middle/ close zone based on median depth from los
zone_tibble = tibble(nflId = zone_nflIds, position = zone_positions, depth = NA, zx = NA, zy = NA, width_radius = NA, depth_radius = NA, color = NA)
close_dist = c(-1, 4)
middle_dist = c(4, 11)
deep_dist = c(11, 25)

for(ni in zone_nflIds){
  play_xs = current_game_defense_lineStrings$x[which(current_game_defense_lineStrings$nflId_ == ni)]
  los_differences = abs(los - play_xs)
  med_differences = median(los_differences)
  zone_tibble[which(zone_tibble$nflId == ni), 'depth'] = if_else(med_differences <= close_dist[2], 'close', if_else(med_differences <= middle_dist[2], 'middle', 'deep'))
}

coverage_number = NA # should be a string number
# classify coverage # based on where safeties and cornerbacks are/ number of each in zone, waterfall this

# depict where zone players should be based on coverage # and webisites such as:
# https://thecollegefootballgirl.com/football-terms/advanced/coverage-schemes/
# depths will be close: 0-4, medium: 4-11, deep: 11-20
# the width of the field can be split up based on diagrams online

number_deep_safeties = sum((zone_tibble$position == 'FS' | zone_tibble$position == 'SS') & zone_tibble$depth == 'deep')
number_deep_middle_cornerbacks = sum((zone_tibble$depth == 'middle' | zone_tibble$depth == 'deep') & zone_tibble$position == 'cornerback')

close_split = c(0, 10, 53 + 1/3 - 10, 53 + 1/3)

if(number_deep_safeties == 0){
  # no deep safeties - cover 0
  coverage_number = 'zero'
  coverage_number_label = 0
  # no splits since this should be man across the board
  deep_split = c()
  middle_split = c()
}else if(number_deep_safeties == 1){
  # one deep safety - cover 1 or cover 3
  # middle/deep cornerbacks zone -> cover 3 else cover 1
  if(number_deep_middle_cornerbacks >= 1){
    coverage_number = 'three'
    coverage_number_label = 3
    deep_split = c(0, (53+1/3)/3, 2*(53+1/3)/3, 53+1/3)
    middle_split = c(0, (53+1/3)/4, (53+1/3)/2, 3*(53+1/3)/4, 53+1/3)
  }else{
    coverage_number = 'one'
    coverage_number_label = 1
    deep_split = c((53+1/3)/4, 3*(53+1/3)/4)
    middle_split = (0:5 * rep(53+1/3, 6))/5
  }
}else{
  # two deep safety - cover 2 or cover 4
  # middle/deep cornerbacks zone -> cover 4 else cover 2
  if(number_deep_middle_cornerbacks >= 1){
    coverage_number = 'four'
    coverage_number_label = 4
    deep_split = (0:4 * rep(53+1/3, 5))/4
    middle_split = (0:3 * rep(53+1/3, 4))/3
  }else{
    coverage_number = 'two'
    coverage_number_label = 2
    deep_split = (0:2 * rep(53+1/3, 3))/2
    middle_split = (0:5 * rep(53+1/3, 6))/5
  }
}

# for each zone player put their xy coordinate of which zone their in based on their depth and which split they are closeset to
# making sure that that split isn't already taken
max_splits = max(length(close_split), length(middle_split), length(deep_split)) - 1
zone_centersx = matrix(-1000, nrow = 3, ncol = max_splits)
zone_centersy = matrix(-1000, nrow = 3, ncol = max_splits)
for(i in 1:3){
  for(j in 1:max_splits){
    if(i == 1){
      if(j+1 > length(deep_split)){
        next
      }
      zone_centersx[i, j] = mean(deep_dist)
      zone_centersy[i, j] = mean(deep_split[j:(j+1)])
    }else if(i == 2){
      if(j+1 > length(middle_split)){
        next
      }
      zone_centersx[i, j] = mean(middle_dist)
      zone_centersy[i, j] = mean(middle_split[j:(j+1)])
    }else{
      if(j+1 > length(close_split)){
        next
      }
      zone_centersx[i, j] = mean(close_dist)
      zone_centersy[i, j] = mean(close_split[j:(j+1)])
    }
  }
}

ball_sign = sign(los - current_game_ball_lineStrings$x[5])
for(ni in zone_nflIds){
  current_xys = current_game_defense_lineStrings[which(current_game_defense_lineStrings$nflId_ == ni), c('x', 'y')]
  dist_array = array(data=NA, dim=c(nrow(zone_centersx), ncol(zone_centersx), nrow(current_xys)))
  for(kk in 1:nrow(current_xys)){
    for(ii in 1:nrow(zone_centersx)){
      for(jj in 1:ncol(zone_centersy)){
        dist_array[ii, jj, kk] = sqrt((zone_centersx[ii, jj] - current_xys$x[kk])**2 + (zone_centersy[ii, jj] - current_xys$y[kk])**2)
      }
    }
  }
  median_dists = apply(dist_array, c(1,2), median, na.rm = TRUE)
  min_index = which(median_dists == min(median_dists), arr.ind=T)
  zone_tibble[which(zone_tibble$nflId == ni),]$zx = los + ball_sign*zone_centersx[min_index[1], min_index[2]]
  zone_tibble[which(zone_tibble$nflId == ni),]$zy = zone_centersy[min_index[1], min_index[2]]
  
  # get radius by finding the minimum span of _split and _dist then dividing by 2
  if(min_index[1] == 1){
    width_radius = abs(deep_split[min_index[2]] - deep_split[min_index[2]+1])/2
    depth_radius = abs(deep_dist[1] - deep_dist[2])/2
  }else if(min_index[1] == 2){
    width_radius = abs(middle_split[min_index[2]] - middle_split[min_index[2]+1])/2
    depth_radius = abs(middle_dist[1] - middle_dist[2])/2
  }else{
    width_radius = abs(close_split[min_index[2]] - close_split[min_index[2]+1])/2
    depth_radius = abs(close_dist[1] - close_dist[2])/2
  }
  
  zone_tibble[which(zone_tibble$nflId == ni),]$width_radius = width_radius
  zone_tibble[which(zone_tibble$nflId == ni),]$depth_radius = depth_radius
  
  # get color by which depth was selected yellow, red or green
  if(min_index[1] == 1){
    zone_tibble[which(zone_tibble$nflId == ni),]$color = 'red'
  }else if(min_index[1] == 2){
    zone_tibble[which(zone_tibble$nflId == ni),]$color = 'yellow'
  }else{
    zone_tibble[which(zone_tibble$nflId == ni),]$color = 'orange'
  }
}

# expand for drawing
zone_tibble_draw = tibble(nflId = current_game_defense_lineStrings$nflId_[which(current_game_defense_lineStrings$nflId_ %in% zone_nflIds)], position = current_game_defense_lineStrings$position[which(current_game_defense_lineStrings$nflId_ %in% zone_nflIds)], playerx = current_game_defense_lineStrings$x[which(current_game_defense_lineStrings$nflId_ %in% zone_nflIds)], playery = current_game_defense_lineStrings$y[which(current_game_defense_lineStrings$nflId_ %in% zone_nflIds)], zonex = NA, zoney = NA, timestep = current_game_defense_lineStrings$timestep[which(current_game_defense_lineStrings$nflId_ %in% zone_nflIds)], width_radius = NA, depth_radius = NA, Color = NA)
for(i in 1:nrow(zone_tibble_draw)){
  current_nflId = zone_tibble_draw$nflId[i]
  zone_tibble_draw$zonex[i] = zone_tibble$zx[which(zone_tibble$nflId == current_nflId)]
  zone_tibble_draw$zoney[i] = zone_tibble$zy[which(zone_tibble$nflId == current_nflId)]
  zone_tibble_draw$width_radius[i] = zone_tibble$width_radius[which(zone_tibble$nflId == current_nflId)]
  zone_tibble_draw$depth_radius[i] = zone_tibble$depth_radius[which(zone_tibble$nflId == current_nflId)]
  zone_tibble_draw$Color[i] = zone_tibble$color[which(zone_tibble$nflId == current_nflId)]
}

# make a man tibble that has where the line segments should be, that is where the defender is and where the closest wide receiver is
man_nflIds = individual_coverage$nflId[which(individual_coverage$man)]
man_tibble = tibble(nflId = man_nflIds, position = individual_coverage$position[which(individual_coverage$man)], closest_offense_nflId = NA)

#mode function from https://www.tutorialspoint.com/r/r_mean_median_mode.htm
getmode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

for(ni in man_nflIds){
  current_xys = current_game_defense_lineStrings[which(current_game_defense_lineStrings$nflId_ == ni), c('x', 'y', 'timestep')]
  
  # at each timestep calculate the difference between the xy and all the offensive playmakers
  # keep track of which player defender is closest to
  closest_offense_nflIds = c()
  for(i in 1:nrow(current_xys)){
    temp_timestep = current_xys$timestep[i]
    offense_xys = current_game_offense_lineStrings[which(current_game_offense_lineStrings$timestep == temp_timestep), c('x', 'y', 'nflId_')]
    min_dist = 1e10
    min_ind = -1
    for(j in 1:nrow(offense_xys)){
      current_dist = sqrt((current_xys$x[i] - offense_xys$x[j])**2 + (current_xys$y[i] - offense_xys$y[j])**2)
      if(current_dist < min_dist){
        min_dist = current_dist
        min_ind = j
      }
    }
    closest_offense_nflIds = append(closest_offense_nflIds, offense_xys$nflId_[min_ind])
  }
  
  # take mode of nflId of offensive players
  closest_receiver_nflId = getmode(closest_offense_nflIds) # check to make sure this isn't a character
  
  # save that nflId, will expand later for graphing
  man_tibble[which(man_tibble$nflId == ni),]$closest_offense_nflId = closest_receiver_nflId
}

# expand for drawing
man_tibble_draw = tibble(nflId = current_game_defense_lineStrings$nflId_[which(current_game_defense_lineStrings$nflId_ %in% man_nflIds)], position = current_game_defense_lineStrings$position[which(current_game_defense_lineStrings$nflId_ %in% man_nflIds)], defenderx = current_game_defense_lineStrings$x[which(current_game_defense_lineStrings$nflId_ %in% man_nflIds)], defendery = current_game_defense_lineStrings$y[which(current_game_defense_lineStrings$nflId_ %in% man_nflIds)], timestep = current_game_defense_lineStrings$timestep[which(current_game_defense_lineStrings$nflId_ %in% man_nflIds)], offensex = NA, offensey = NA)
for(i in 1:nrow(man_tibble_draw)){
  
  current_nflId = man_tibble_draw$nflId[i]
  offense_nflId = man_tibble$closest_offense_nflId[which(man_tibble$nflId == current_nflId)]
  man_tibble_draw$offensex[i] = current_game_offense_lineStrings$x[which((current_game_offense_lineStrings$nflId_ == offense_nflId) & (current_game_offense_lineStrings$timestep == man_tibble_draw$timestep[i]))]
  man_tibble_draw$offensey[i] = current_game_offense_lineStrings$y[which((current_game_offense_lineStrings$nflId_ == offense_nflId) & (current_game_offense_lineStrings$timestep == man_tibble_draw$timestep[i]))]
  
}


# make a blitz tibble that has where the arrows should be point to, that is where the defender is and where the arrow should point at
blitz_nflIds = individual_coverage$nflId[which(individual_coverage$blitz)]

blitz_tibble_draw = tibble(nflId = current_game_defense_lineStrings$nflId_[which(current_game_defense_lineStrings$nflId_ %in% blitz_nflIds)], position = current_game_defense_lineStrings$position[which(current_game_defense_lineStrings$nflId_ %in% blitz_nflIds)], arrow_basex = current_game_defense_lineStrings$x[which(current_game_defense_lineStrings$nflId_ %in% blitz_nflIds)], arrow_basey = current_game_defense_lineStrings$y[which(current_game_defense_lineStrings$nflId_ %in% blitz_nflIds)], arrow_tipx = NA, arrow_tipy = NA, color = 'red', timestep = current_game_defense_lineStrings$timestep[which(current_game_defense_lineStrings$nflId_ %in% blitz_nflIds)])

for(i in 1:nrow(blitz_tibble_draw)){
  current_y = blitz_tibble_draw$arrow_basey[i]
  if(current_y <= .5*(53+1/3)){
    blitz_tibble_draw[i,]$arrow_tipy = current_y + 3
  }else{
    blitz_tibble_draw[i,]$arrow_tipy = current_y - 3
  }
  
  current_nflId = blitz_tibble_draw$nflId[i]
  current_xs = blitz_tibble_draw$arrow_basex[which(blitz_tibble_draw$nflId == current_nflId)]
  blitz_direction = sign(current_xs[1] - current_xs[6])
  blitz_tibble_draw$arrow_tipx[i] = blitz_tibble_draw$arrow_basex[i] - 4*blitz_direction
}

# draw man connecting line to closest receiver on average throughout play, blitz arrow, and zone where
# players should be with a line connecting player to center of zone.

# text df with nflId, position, lastName, route, x, y, timestep
text_tibble = bind_rows(current_game_offense_lineStrings, current_game_defense_lineStrings) %>%
  mutate(uniqueId = NULL) %>%
  mutate(lastName = NA) %>%
  mutate(route = '')

for(i in 1:nrow(text_tibble)){
  if(text_tibble$side[i] == 'offense'){
    text_tibble$route[i] = current_routes$route[which(current_routes$nflId == text_tibble$nflId_[i])]
  }
  text_tibble$lastName[i] = players$LastName[which(players$nflId == text_tibble$nflId_[i])]
}
text_tibble$side = NULL

text_animation = list(geom_label(data = text_tibble, aes(y, x, label=position, hjust=-.4)),
  geom_label(data = text_tibble, aes(y, x, label=lastName, vjust=-.3)))
  # geom_text(data = text_tibble, aes(y, x, label=route, hjust=-.4)))

# man animation
man_animation = geom_segment(data=man_tibble_draw, aes(x=defendery, y=defenderx, xend=offensey, yend=offensex))

# blitz animation
blitz_animation = geom_segment(data=blitz_tibble_draw, aes(x=arrow_basey, y=arrow_basex, xend=arrow_tipy, yend=arrow_tipx), arrow=arrow(), size=2, color="red")

# zone animation
zone_animation = list(geom_ellipse(data=zone_tibble_draw, aes(x0=zoney, y0=zonex, a=width_radius, b=depth_radius, angle=0, fill=Color, alpha=0.01), inherit.aes = F, show.legend = F), geom_segment(data=zone_tibble_draw, aes(x=playery, y=playerx, xend=zoney, yend=zonex), color=zone_tibble_draw$Color))

merged_lineStrings = bind_rows(current_game_offense_lineStrings, current_game_defense_lineStrings, current_game_ball_lineStrings) %>%
  mutate(position = NULL)

animate_coverage = ggplot(merged_lineStrings, aes(y, x)) +
  nfl_theme +
  geom_hline(yintercept = los, colour = 'red', linetype = 'dashed') +
  geom_point(size=4, aes(col=side)) +
  scale_color_manual(values = c('brown', 'orange', 'navyblue')) +
  man_animation +
  blitz_animation +
  zone_animation +
  text_animation + 
  transition_manual(timestep) +
  labs(title = paste('GameId:', my_gameId, ' PlayId:', my_playId, ' Frame: {current_frame} Cover {coverage_number_label}'))
animate_coverage

anim_save(filename = 'example_coverage.gif')

