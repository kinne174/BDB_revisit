library(readr)
library(ggplot2)
library(dplyr)
library(gganimate)

source('C:/Users/Mitch/PycharmProjects/BDB_revisit/nfl_theme.R')
source('C:/Users/Mitch/PycharmProjects/BDB_revisit/load_files_helper_functions.R')

visualize_play = function(my_gameId, my_playId){
  # my_gameId = 2017091009
  # my_playId = 1596
  
  lineStrings_lookups = load_both_lookups_lineStrings_helper(gameId = my_gameId, include_ball=T)
  current_game_offense_lineStrings = lineStrings_lookups[[1]]
  current_game_defense_lineStrings = lineStrings_lookups[[2]]
  current_game_ball_lineStrings = lineStrings_lookups[[3]]
  current_game_offense_lookup = lineStrings_lookups[[4]]
  current_game_defense_lookup = lineStrings_lookups[[5]]
  
  plays_filename = 'C:/Users/Mitch/Documents/UofM/Fall 2018/NFL/Data/plays.csv'
  plays_df = read_csv(plays_filename, col_types = cols()) 
  
  current_game_offense_lookup = current_game_offense_lookup %>%
    filter(playId == my_playId)
  
  current_game_defense_lookup = current_game_defense_lookup %>%
    filter(playId == my_playId)
  
  current_game_offense_lineStrings = current_game_offense_lineStrings %>%
    rowwise() %>%
    mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
    mutate(nflId_ = as.numeric(substr(uniqueId, gregexpr('-', uniqueId)[[1]][2] + 1, nchar(uniqueId)))) %>%
    filter(playId_ == my_playId) %>%
    mutate(playId_ = NULL) %>%
    mutate(side = 'offense') %>%
    mutate(position = current_game_offense_lookup$position[current_game_offense_lookup$nflId == nflId_]) %>%
    mutate(nflId_ = NULL)
  
  current_game_defense_lineStrings = current_game_defense_lineStrings %>%
    rowwise() %>%
    mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
    mutate(nflId_ = as.numeric(substr(uniqueId, gregexpr('-', uniqueId)[[1]][2] + 1, nchar(uniqueId)))) %>%
    filter(playId_ == my_playId) %>%
    mutate(playId_ = NULL) %>%
    mutate(side = 'defense') %>%
    mutate(position = current_game_defense_lookup$position[current_game_defense_lookup$nflId == nflId_]) %>%
    mutate(nflId_ = NULL)
  
  current_game_ball_lineStrings = current_game_ball_lineStrings %>%
    rowwise() %>%
    mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
    filter(playId_ == my_playId) %>%
    mutate(playId_ = NULL) %>%
    mutate(side = 'ball') %>%
    mutate(position = '')
  
  merged_lineStrings = bind_rows(current_game_offense_lineStrings, current_game_defense_lineStrings, current_game_ball_lineStrings)
  
  # if(min(table(merged_lineStrings$timestep)) != max(table(merged_lineStrings$timestep))){
  #   stop('Something went wrong, there is not the same players for each timestep')
  # }
  
  # line of scrimmage
  los_init = as.numeric(plays_df$yardlineNumber[plays_df$gameId == my_gameId & plays_df$playId == my_playId])
  los1 = 110 - los_init
  los2 = 10 + los_init
  
  ball_x = current_game_ball_lineStrings$x[1]
  if(abs(los1 - ball_x) < abs(los2 - ball_x)){
    los = los1
  }else{
    los = los2
  }
  # depending on where ball is place the los there (y or x? use x), not really worried about first down right now
  
  animate_play = ggplot(merged_lineStrings, aes(y, x)) +
    nfl_theme +
    geom_hline(yintercept = los, colour = 'red', linetype = 'dashed') +
    geom_point(size=4, aes(col=side)) +
    scale_color_manual(values = c('brown', 'orange', 'navyblue')) +
    geom_text(aes(label=position, hjust=-.6)) +
    transition_manual(timestep) +
    labs(title = paste('GameId:', my_gameId, ' PlayId:', my_playId, ' Frame: {current_frame}'))
    
    
  return(animate_play)
}
