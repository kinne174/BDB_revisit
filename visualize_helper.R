source('C:/Users/Mitch/PycharmProjects/BDB_revisit/visualize_play.R')

my_gameId = 2017091101

ref_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/gameId2row.csv'
ref = read_csv(ref_filename, col_types = cols())

row_gameId = which(ref$all_gameIds==my_gameId) #which row is the current gameId in the reference table


offense_lookup_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/offense_lookup.csv'
current_game_offense_lookup = read_csv(offense_lookup_filename, skip=ref$offense_lookup_indices[row_gameId], n_max = ref$offense_lookup_indices[row_gameId+1] - ref$offense_lookup_indices[row_gameId], col_names = c('uniqueId', 'gameId', 'playId', 'nflId', 'position', 'leftOfBall', 'routeLabel', 'intended'), col_types = cols())

all_playIds = as.numeric(current_game_offense_lookup$playId)
my_playId = all_playIds[2]

visualize_play(my_gameId = my_gameId, my_playId = my_playId)
