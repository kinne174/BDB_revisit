library(readr)
library(ggplot2)
library(dplyr)

source('C:/Users/Mitch/PycharmProjects/BDB_revisit/nfl_theme.R')

my_gameId = 2017091009
my_playId = 1596

games_filename = 'C:/Users/Mitch/PycharmProjects/NFL/Data/games.csv'
plays_filename = 'C:/Users/Mitch/Documents/UofM/Fall 2018/NFL/Data/plays.csv'
plays_df = read_csv(plays_filename) # doesn't exist

offense_lineStrings_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/offense_lineStrings.csv'
defense_lineStrings_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/defense_lineStrings.csv'

offense_lookup_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/offense_lookup.csv'
defense_lookup_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/defense_lookup.csv'

ball_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/ball_lineStrings.csv'

# can now use the reference gameId2row.csv and read_csv() with skip rows and nrows to read in the specific game based on
# gameId then find playId within those tibbles using dplyr

# then need to reshape it with dplyr again probably in a form to apply ggplot and transition_manual
ref_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/gameId2row.csv'
ref = read_csv(ref_filename)

row_gameId = which(ref$all_gameIds==my_gameId) #which row is the current gameId in the reference table
if (row_gameId != nrow(ref)){

  current_game_offense_lineStrings = read_csv(offense_lineStrings_filename, skip=ref$offense_lineStrings_indices[row_gameId], n_max = ref$offense_lineStrings_indices[row_gameId + 1] - ref$offense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'))
  current_game_defense_lineStrings = read_csv(defense_lineStrings_filename, skip=ref$defense_lineStrings_indices[row_gameId], n_max = ref$defense_lineStrings_indices[row_gameId + 1] - ref$defense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'))
  current_game_ball_lineStrings = read_csv(ball_filename, skip=ref$ball_indices[row_gameId], n_max = ref$ball_indices[row_gameId + 1] - ref$ball_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'))
  
  current_game_offense_lookup = read_csv(offense_lookup_filename, skip=ref$offense_lookup_indices[row_gameId], n_max = ref$offense_lookup_indices[row_gameId+1] - ref$offense_lookup_indices[row_gameId], col_names = c('uniqueId', 'gameId', 'playId', 'nflId', 'position', 'leftOfBall', 'routeLabel', 'intended'))
  current_game_defense_lookup = read_csv(defense_lookup_filename, skip=ref$defense_lookup_indices[row_gameId], n_max = ref$defense_lookup_indices[row_gameId+1] - ref$defense_lookup_indices[row_gameId], col_names = c('uniqueId', 'gameId', 'playId', 'nflId', 'position'))
  
}else{
  current_game_offense_lineStrings = read_csv(offense_lineStrings_filename, skip=ref$offense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'))
  current_game_defense_lineStrings = read_csv(defense_lineStrings_filename, skip=ref$defense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'))
  current_game_ball_lineStrings = read_csv(ball_filename, skip=ref$ball_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'))
  
  current_game_offense_lookup = read_csv(offense_lookup_filename, skip=ref$offense_lookup_indices[row_gameId], col_names = c('uniqueId', 'gameId', 'playId', 'nflId', 'position', 'leftOfBall', 'routeLabel', 'intended'))
  current_game_defense_lookup = read_csv(defense_lookup_filename, skip=ref$defense_lookup_indices[row_gameId], col_names = c('uniqueId', 'gameId', 'playId', 'nflId', 'position'))
}

current_game_offense_lineStrings = current_game_offense_lineStrings %>%
  rowwise() %>%
  mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
  filter(playId_ == my_playId) %>%
  mutate(playId_ = NULL) %>%
  mutate(side = 'offense')

current_game_defense_lineStrings = current_game_defense_lineStrings %>%
  rowwise() %>%
  mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
  filter(playId_ == my_playId) %>%
  mutate(playId_ = NULL) %>%
  mutate(side = 'defense')

current_game_ball_lineStrings = current_game_ball_lineStrings %>%
  rowwise() %>%
  mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
  filter(playId_ == my_playId) %>%
  mutate(playId_ = NULL) %>%
  mutate(side = 'ball')

current_game_offense_lookup = current_game_offense_lookup %>%
  filter(playId == my_playId)

current_game_defense_lookup = current_game_defense_lookup %>%
  filter(playId == my_playId)

merged_lineStrings = bind_rows(current_game_offense_lineStrings, current_game_defense_lineStrings, current_game_ball_lineStrings)

if(min(table(merged_lineStrings$timestep)) != max(table(merged_lineStrings$timestep))){
  stop('Something went wrong, there is not the same players for each timestep')
}

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
  geom_point(size=3, aes(col=side)) +
  transition_manual(timestep)
  
animate_play
