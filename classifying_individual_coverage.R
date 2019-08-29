source('C:/Users/Mitch/PycharmProjects/BDB_revisit/load_files_helper_functions.R')
source('C:/Users/Mitch/PycharmProjects/BDB_revisit/visualize_play.R')
source('C:/Users/Mitch/PycharmProjects/BDB_revisit/nfl_theme.R')

# for a specific gameId and playId load in the defense and offense lineStrings using the reference tibble
# can also load in defense lookups since I'll need positions from them to determine overall coverage
# also load in line of scrimmage to help classifying blitz

my_gameId = 2017091101
my_playId = 311

lineStrings_lookups = load_both_lookups_lineStrings_helper(gameId = my_gameId, playId = my_playId, include_ball=T)
current_game_offense_lineStrings = lineStrings_lookups[[1]]
current_game_defense_lineStrings = lineStrings_lookups[[2]]
current_game_ball_lineStrings = lineStrings_lookups[[3]]
current_game_offense_lookup = lineStrings_lookups[[4]]
current_game_defense_lookup = lineStrings_lookups[[5]]

current_game_defense_lineStrings = current_game_defense_lineStrings %>%
  rowwise() %>%
  mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
  mutate(nflId_ = as.numeric(substr(uniqueId, gregexpr('-', uniqueId)[[1]][2] + 1, nchar(uniqueId)))) %>%
  filter(playId_ == my_playId) %>%
  mutate(playId_ = NULL) %>%
  mutate(side = 'defense')

current_game_offense_lineStrings = current_game_offense_lineStrings %>%
  rowwise() %>%
  mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
  filter(playId_ == my_playId) %>%
  mutate(playId_ = NULL) %>%
  mutate(individualCoverage = '') %>%
  mutate(side = 'offense')

current_game_ball_lineStrings = current_game_ball_lineStrings %>%
  rowwise() %>%
  mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
  filter(playId_ == my_playId) %>%
  mutate(playId_ = NULL)

out_individual_coverages = current_game_defense_lookup %>%
  filter(playId == my_playId) %>%
  # mutate(position = NULL) %>%
  mutate(blitz = NA) %>%
  mutate(man = NA) %>%
  mutate(zone = NA) %>%
  mutate(averageClosestReceiver = NA) %>%
  mutate(totalDistance = NA) %>%
  mutate(losDifference = NA) %>%
  mutate(uniqueClosestReciever = NA) %>%
  mutate(individualCoverage = NA)
  

plays_filename = 'C:/Users/Mitch/Documents/UofM/Fall 2018/NFL/Data/plays.csv'
plays_df = read_csv(plays_filename, col_types = cols()) 

los_init = as.numeric(plays_df$yardlineNumber[plays_df$gameId == my_gameId & plays_df$playId == my_playId])
los1 = 110 - los_init
los2 = 10 + los_init

ball_x = current_game_ball_lineStrings$x[1]
if(abs(los1 - ball_x) < abs(los2 - ball_x)){
  los = los1
}else{
  los = los2
}

unique_nflIds = unique(out_individual_coverages$nflId)

# classify blitz
# for each defensive player see if they're have x coordinates straddling line of scrimmage, if they do then classify
# as blitz, otherwise not blitz
for(ni in unique_nflIds){
  rows_ni = which((current_game_defense_lineStrings$nflId_ == ni) & (current_game_defense_lineStrings$timestep <= 15))
  los_differences = current_game_defense_lineStrings$x[rows_ni] - los
  if((any(los_differences > 0) & any(los_differences < 0)) | (any(los_differences + 0.25 > 0) & any(los_differences + 0.25 < 0)) | (any(los_differences - 0.25 > 0) & any(los_differences - 0.25 < 0))){
    out_individual_coverages[which(out_individual_coverages$nflId == ni),]$blitz = TRUE
    out_individual_coverages[which(out_individual_coverages$nflId == ni),]$man = FALSE
    out_individual_coverages[which(out_individual_coverages$nflId == ni),]$zone = FALSE
  }else{
    out_individual_coverages[which(out_individual_coverages$nflId == ni),]$blitz = FALSE
  }
}
  
# classify man
# for each non blitz player get summary statistics such as average distance to closest receiver, total distance travelled,
# absolute difference between starting x and los, number of unique closest receivers, use these to classify man vs not man
# coverage, probably through logic first and then through fitting possibly with active learning
non_blitz_nflIds = out_individual_coverages$nflId[which(!out_individual_coverages$blitz)]

for(ni in non_blitz_nflIds){
  rows_ni = which(current_game_defense_lineStrings$nflId_ == ni, arr.ind = T)
  los_difference = abs(ball_x - current_game_defense_lineStrings$x[rows_ni[1]])
  
  # min closest receiver at each time step then take average and number of unique wide receivers
  all_distances = c()
  all_receiver_ids = c()
  for(r in rows_ni){
    current_timestep = current_game_defense_lineStrings$timestep[r]
    current_xy = current_game_defense_lineStrings[r, c('x', 'y')]
    offense_xys = current_game_offense_lineStrings[which(current_game_offense_lineStrings$timestep == current_timestep), c('uniqueId', 'x', 'y')]
    current_distances = c()
    for(xy_row in 1:nrow(offense_xys)){
      xy_mat = rbind(current_xy, offense_xys[xy_row, c('x', 'y')])
      dist_mat = dist(xy_mat)
      current_distances[xy_row] = dist_mat[1]
    }
    all_distances = append(all_distances, min(current_distances))
    closest_uniqueId = offense_xys$uniqueId[which.min(current_distances)]
    all_receiver_ids = append(all_receiver_ids, closest_uniqueId)
  }
  closest_average = mean(all_distances)
  number_closest_receivers = length(unique(all_receiver_ids))
  
  # total distance traveled
  distances = c()
  for(r in rows_ni[2:length(rows_ni)]){
    current_xy = current_game_defense_lineStrings[c(r, r - 1), c('x', 'y')]
    current_distance = dist(current_xy)[1]
    distances = append(distances, current_distance)
  }
  total_distance = sum(distances)
  
  ni_row = which(out_individual_coverages$nflId == ni)
  out_individual_coverages[ni_row,]$averageClosestReceiver = closest_average
  out_individual_coverages[ni_row,]$totalDistance = total_distance
  out_individual_coverages[ni_row,]$losDifference = los_difference
  out_individual_coverages[ni_row,]$uniqueClosestReciever = number_closest_receivers
  
  # now use these to classify man coverage or not
  out_individual_coverages[ni_row,]$man = (number_closest_receivers <= 2) & (los_difference <= 4)
}

# classify zone
# for each non blitz and not man classify as zone
for(i in 1:nrow(out_individual_coverages)){
  out_individual_coverages[i,'zone'] = !any(c(out_individual_coverages$blitz[i], out_individual_coverages$man[i]))
}

# output should be the defense lookup file but with an extra character column titled 'individualCoverage' with the 
# players coverage for that play, one of 'blitz', 'man', or 'zone'

out_individual_coverages$individualCoverage[which(out_individual_coverages$blitz)] = 'blitz'
out_individual_coverages$individualCoverage[which(out_individual_coverages$man)] = 'man'
out_individual_coverages$individualCoverage[which(out_individual_coverages$zone)] = 'zone'


# next thing is to start doing some learning for man coverage, make sure that label is correct before moving onto zone,
# possibly can call animate play and then add on another text pointer with coverage to get a visual of what is being
# assigned, add positions to lineStrings then should be able to add it to the ggplot
current_game_defense_lineStrings$individualCoverage = NA
for(i in 1:nrow(out_individual_coverages)){
  current_game_defense_lineStrings$individualCoverage[which(current_game_defense_lineStrings$nflId_ == out_individual_coverages$nflId[i])] = out_individual_coverages$individualCoverage[i]
}

animate_play = ggplot(bind_rows(current_game_defense_lineStrings, current_game_offense_lineStrings), aes(y, x)) +
  nfl_theme +
  geom_hline(yintercept = los, colour = 'red', linetype = 'dashed') +
  geom_point(size=4, aes(col=side)) +
  scale_color_manual(values = c('orange', 'navyblue')) +
  geom_text(aes(label=individualCoverage, hjust=1.6)) +
  transition_manual(timestep)
animate_play

