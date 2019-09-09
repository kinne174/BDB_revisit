# function to load rows of dataframes for a specific gameId and playId
library(readr)

load_lineStrings_helper = function(gameId, include_ball=T){
  offense_lineStrings_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/offense_lineStrings.csv'
  defense_lineStrings_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/defense_lineStrings.csv'
  
  ref_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/gameId2row.csv'
  ref = read_csv(ref_filename, col_types = cols())
  
  row_gameId = which(ref$all_gameIds==my_gameId) #which row is the current gameId in the reference table
  
  if(!include_ball){
    if (row_gameId != nrow(ref)){
      
      current_game_offense_lineStrings = read_csv(offense_lineStrings_filename, skip=ref$offense_lineStrings_indices[row_gameId], n_max = ref$offense_lineStrings_indices[row_gameId + 1] - ref$offense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'), col_types = cols())
      current_game_defense_lineStrings = read_csv(defense_lineStrings_filename, skip=ref$defense_lineStrings_indices[row_gameId], n_max = ref$defense_lineStrings_indices[row_gameId + 1] - ref$defense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'), col_types = cols())
      
    }else{
      current_game_offense_lineStrings = read_csv(offense_lineStrings_filename, skip=ref$offense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'), col_types = cols())
      current_game_defense_lineStrings = read_csv(defense_lineStrings_filename, skip=ref$defense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'), col_types = cols())
    }
    
    out_lineStrings_list = list(current_game_offense_lineStrings, current_game_defense_lineStrings)
  }else{
    
    ball_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/ball_lineStrings.csv'
    
    if (row_gameId != nrow(ref)){
      current_game_offense_lineStrings = read_csv(offense_lineStrings_filename, skip=ref$offense_lineStrings_indices[row_gameId], n_max = ref$offense_lineStrings_indices[row_gameId + 1] - ref$offense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'), col_types = cols())
      current_game_defense_lineStrings = read_csv(defense_lineStrings_filename, skip=ref$defense_lineStrings_indices[row_gameId], n_max = ref$defense_lineStrings_indices[row_gameId + 1] - ref$defense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'), col_types = cols())
      current_game_ball_lineStrings = read_csv(ball_filename, skip=ref$ball_indices[row_gameId], n_max = ref$ball_indices[row_gameId + 1] - ref$ball_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'), col_types = cols())
      
    }else{
      current_game_offense_lineStrings = read_csv(offense_lineStrings_filename, skip=ref$offense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'), col_types = cols())
      current_game_defense_lineStrings = read_csv(defense_lineStrings_filename, skip=ref$defense_lineStrings_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'), col_types = cols())
      current_game_ball_lineStrings = read_csv(ball_filename, skip=ref$ball_indices[row_gameId], col_names = c('uniqueId', 'x', 'y', 'timestep'), col_types = cols())
    }
    
    out_lineStrings_list = list(current_game_offense_lineStrings, current_game_defense_lineStrings, current_game_ball_lineStrings)
  }
  
  return(out_lineStrings_list)
  
  
}

load_lookups_helper = function(gameId){
  offense_lookup_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/offense_lookup.csv'
  defense_lookup_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/defense_lookup.csv'
  
  ref_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/gameId2row.csv'
  ref = read_csv(ref_filename, col_types = cols())
  
  row_gameId = which(ref$all_gameIds==my_gameId) #which row is the current gameId in the reference table
  
  if (row_gameId != nrow(ref)){
    
    current_game_offense_lookup = read_csv(offense_lookup_filename, skip=ref$offense_lookup_indices[row_gameId], n_max = ref$offense_lookup_indices[row_gameId+1] - ref$offense_lookup_indices[row_gameId], col_names = c('uniqueId', 'gameId', 'playId', 'nflId', 'position', 'leftOfBall', 'routeLabel', 'intended'), col_types = cols())
    current_game_defense_lookup = read_csv(defense_lookup_filename, skip=ref$defense_lookup_indices[row_gameId], n_max = ref$defense_lookup_indices[row_gameId+1] - ref$defense_lookup_indices[row_gameId], col_names = c('uniqueId', 'gameId', 'playId', 'nflId', 'position'), col_types = cols())
    
  }else{
    
    current_game_offense_lookup = read_csv(offense_lookup_filename, skip=ref$offense_lookup_indices[row_gameId], col_names = c('uniqueId', 'gameId', 'playId', 'nflId', 'position', 'leftOfBall', 'routeLabel', 'intended'), col_types = cols())
    current_game_defense_lookup = read_csv(defense_lookup_filename, skip=ref$defense_lookup_indices[row_gameId], col_names = c('uniqueId', 'gameId', 'playId', 'nflId', 'position'), col_types = cols())
  }
  
  return(list(current_game_offense_lookup, current_game_defense_lookup))
}

load_both_lookups_lineStrings_helper = function(gameId, include_ball=T){
  
  out_lineStrings = load_lineStrings_helper(gameId = gameId, include_ball = include_ball)
  out_lookups = load_lookups_helper(gameId = gameId)
  
  return(c(out_lineStrings, out_lookups))
}