# use this to keep running dataframe of relevant information from plays
# mainly appending the info from classifying_individual_coverage
# should also add some columns to keep track of which rows to use in svm (zone or man)

# flow should be to input a gameId and playID (check to see if it is in the running dataframe), coverage takes in the SVM 
# model and empirical distribution statistics then
# outputs the dataset containing the 4 features and the proposed labels
# Then do active learning with zone/man labels and a visual, interactive console to change labels
# Then refit SVM and empirical distribution statistics and append to running dataframe with all info, save that dataframe
# Then get ready for next gameId and playId

source('C:/Users/Mitch/PycharmProjects/BDB_revisit/nfl_theme.R')
source('C:/Users/Mitch/PycharmProjects/BDB_revisit/load_files_helper_functions.R')

library(e1071)
library(dplyr)
library(gganimate)

# load in individualCoverage tibble
individual_coverage_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/individualCoverage.csv'
individual_coverage_tibble = read_csv(individual_coverage_filename, col_types = cols())

# initialize list of SVM model and empirical distribution statistics
# models = list()
# models$SVM = NA
# models$mean = NA
# models$sd = NA
# models$probs = NA

# individual_coverage_tibble = tibble()

threshold = 75
# if(nrow(individual_coverage_tibble) >= threshold){
#   man_indices = which(individual_coverage_tibble$man)
#   models$mean = mean(individual_coverage_tibble$losDifference[man_indices])
#   models$sd = sd(individual_coverage_tibble$losDifference[man_indices])
#   models$probs = c(sum(individual_coverage_tibble$uniqueClosestReciever[man_indices] == 1)/sum(man_indices), sum(individual_coverage_tibble$uniqueClosestReciever[man_indices] == 2)/sum(man_indices), sum(individual_coverage_tibble$uniqueClosestReciever[man_indices] == 3)/sum(man_indices), sum(individual_coverage_tibble$uniqueClosestReciever[man_indices] == 4)/sum(man_indices))
#   models$SVM = svm(man ~ averageClosestReceiver + totalDistance + losDifference + uniqueClosestReciever, data = individual_coverage_tibble[which(individual_coverage_tibble$man | individual_coverage_tibble$zone),], probability=TRUE)
# }


# get gameId and playId
my_gameId = 2017091101

# use Ids and models list to assign individual coverages

plays_filename = 'C:/Users/Mitch/Documents/UofM/Fall 2018/NFL/Data/plays.csv'
plays_df = read_csv(plays_filename, col_types = cols())

all_offense_lookup_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/offense_lookup.csv'
all_offense_lookup = read_csv(all_offense_lookup_filename, col_types = cols())

# start playId from here - for loop over unique playIds in game 
all_playIds = unique(all_offense_lookup$playId[which(all_offense_lookup$gameId == my_gameId)])
my_playId = all_playIds[38]

# load in individualCoverage tibble
individual_coverage_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/individualCoverage.csv'
individual_coverage_tibble = read_csv(individual_coverage_filename, col_types = cols())

if(T){
  stopifnot(!(my_gameId %in% individual_coverage_tibble$gameId & my_playId %in% individual_coverage_tibble$playId))
  
  # get relevant files with current gameId rows
  lineStrings_lookups = load_both_lookups_lineStrings_helper(gameId = my_gameId, include_ball=T)
  current_game_offense_lineStrings = lineStrings_lookups[[1]]
  current_game_defense_lineStrings = lineStrings_lookups[[2]]
  current_game_ball_lineStrings = lineStrings_lookups[[3]]
  current_game_offense_lookup = lineStrings_lookups[[4]]
  current_game_defense_lookup = lineStrings_lookups[[5]]
  
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
  
  current_game_offense_lookup = current_game_offense_lookup %>%
    filter(playId == my_playId)
  
  current_game_offense_lineStrings = current_game_offense_lineStrings %>%
    rowwise() %>%
    mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
    mutate(nflId_ = as.numeric(substr(uniqueId, gregexpr('-', uniqueId)[[1]][2] + 1, nchar(uniqueId)))) %>%
    filter(playId_ == my_playId) %>%
    mutate(playId_ = NULL) %>%
    mutate(side = 'offense') %>%
    mutate(position = current_game_offense_lookup$position[current_game_offense_lookup$nflId == nflId_]) %>%
    mutate(nflId_ = '') %>%
    mutate(individualCoverage = '')
  
  current_game_ball_lineStrings = current_game_ball_lineStrings %>%
    rowwise() %>%
    mutate(playId_ = as.numeric(substr(uniqueId, 12, gregexpr('-', uniqueId)[[1]][2] - 1))) %>%
    filter(playId_ == my_playId) %>%
    mutate(playId_ = NULL) %>%
    mutate(nflId_ = '') %>%
    mutate(side = 'ball') %>%
    mutate(position = '') %>%
    mutate(individualCoverage = '')
  
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
  
  confidence_probabilities = c()
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
    
    if(nrow(individual_coverage_tibble) <= threshold){
      out_individual_coverages[ni_row,]$man = (number_closest_receivers <= 2) & (los_difference <= 4)
    }else{
      if(any(is.na(models$SVM), is.na(models$mean), is.na(models$sd))){
        stop('The threshold has been reached but the models are not initialized')
      }
      svm_prob = predict(models$SVM, out_individual_coverages[ni_row, c('averageClosestReceiver', 'totalDistance', 'losDifference', 'uniqueClosestReciever')], probability=TRUE)
      
      empirical_normal_prob = 2*pnorm(-1*abs(los_difference - models$mean)/models$sd)
      empirical_multinomial_prob = models$probs[number_closest_receivers]
      empirical_combined = mean(c(empirical_normal_prob, empirical_multinomial_prob))
      
      svm_weight = exp(-1/(-.67 + nrow(individual_coverage_tibble)/49.58))# check this
      
      svm_empirical_combined = (1 - svm_weight) * empirical_combined + svm_weight * svm_prob
      confidence_probabilities = append(confidence_probabilities, abs(svm_empirical_combined - 0.5))
      
      out_individual_coverages[ni_row,]$man = svm_empirical_combined >= 0.5
    }
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
  
  # active learning part here
  # should be based on how confident model is, only show for not confident labelings
  if(length(confidence_probabilities) > 1){
    cat('Confidence probabilities away from 0.50 are\n')
    print(confidence_probabilities)
    if(mean(confidence_probabilities) < 0.20){
    cat('Low confidence in selection. You should take a look at this play!\n')
    }
  }
  
  #visualization
  current_game_defense_lineStrings = current_game_defense_lineStrings %>%
    rowwise() %>%
    mutate(individualCoverage = out_individual_coverages$individualCoverage[nflId_ == out_individual_coverages$nflId]) %>%
    mutate(nflId_ = as.character(nflId_))
  
  merged_lineStrings = bind_rows(current_game_offense_lineStrings, current_game_defense_lineStrings, current_game_ball_lineStrings)
  
  animate_play = ggplot(merged_lineStrings, aes(y, x)) +
    nfl_theme +
    geom_hline(yintercept = los, colour = 'red', linetype = 'dashed') +
    geom_point(size=4, aes(col=side)) +
    scale_color_manual(values = c('brown', 'orange', 'navyblue')) +
    geom_text(aes(label=position, hjust=-.6)) +
    geom_text(aes(label=individualCoverage, hjust=1.3)) +
    geom_text(aes(label=nflId_, vjust=-1.5)) +
    transition_manual(timestep) +
    labs(title = paste('GameId:', my_gameId, ' PlayId:', my_playId, ' Frame: {current_frame}'))
}

animate_play

#question asking
if(T){
  changeable_indices = which(out_individual_coverages$man | out_individual_coverages$zone, arr.ind = T)
  changeable_nflIds = out_individual_coverages$nflId[changeable_indices]


  cat('The changeable indices are\n')
  for(i in 1:length(changeable_indices)){
    cat(changeable_indices[i], changeable_nflIds[i], '\n')
  }
}

user_input = readline(prompt = 'Indices to change: ')

if(T){
  if(!(user_input == '')){
    indices_to_change = as.numeric(strsplit(user_input, " ")[[1]])
    for(i in indices_to_change){
      out_individual_coverages$zone[i] = !out_individual_coverages$zone[i]
      out_individual_coverages$man[i] = !out_individual_coverages$man[i]
    }
  }
  
  # fit models
  # first one will be just a copy
  # individual_coverage_tibble = out_individual_coverages
  
  individual_coverage_tibble = bind_rows(individual_coverage_tibble, out_individual_coverages)
  
  if(nrow(individual_coverage_tibble) >= threshold){
    man_indices = which(individual_coverage_tibble$man)
    models$mean = mean(individual_coverage_tibble$losDifference[man_indices])
    models$sd = sd(individual_coverage_tibble$losDifference[man_indices])
    models$probs = c(sum(individual_coverage_tibble$uniqueClosestReciever[man_indices] == 1)/length(man_indices), sum(individual_coverage_tibble$uniqueClosestReciever[man_indices] == 2)/length(man_indices), sum(individual_coverage_tibble$uniqueClosestReciever[man_indices] == 3)/length(man_indices), sum(individual_coverage_tibble$uniqueClosestReciever[man_indices] == 4)/length(man_indices))
    models$SVM = svm(as.factor(man) ~ averageClosestReceiver + totalDistance + losDifference + uniqueClosestReciever, data = individual_coverage_tibble[which(individual_coverage_tibble$man | individual_coverage_tibble$zone),], probability = TRUE)
  }
  
  # how does svm do on training data
  training_prediction = attr(predict(models$SVM, individual_coverage_tibble[which(individual_coverage_tibble$man | individual_coverage_tibble$zone), c('averageClosestReceiver', 'totalDistance', 'losDifference', 'uniqueClosestReciever')], probability = TRUE), 'probabilities')[,1]
  correct_ = sum((training_prediction >= 0.5) == individual_coverage_tibble[which(individual_coverage_tibble$man | individual_coverage_tibble$zone), c('man')])/nrow(individual_coverage_tibble[which(individual_coverage_tibble$man | individual_coverage_tibble$zone),])
  cat('The correct percentage in training is: ', round(correct_, 3), '\n')
  
  # save individual_coverage_tibble to csv
  write_csv(individual_coverage_tibble, individual_coverage_filename)
}
