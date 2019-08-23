library(readr)
library(ggplot2)
library(dplyr)

source('C:/Users/Mitch/PycharmProjects/BDB_revisit/nfl_theme.R')

gameId = 2017091009
playId = 1596

games_filename = 'C:\Users\Mitch\PycharmProjects\NFL\Data\games.csv'
plays_filename = 'C:\Users\Mitch\PycharmProjects\NFL\Data\plays.csv'

offense_lineStrings_filename = 'C:\Users\Mitch\PycharmProjects\BDB_revisit\Data\offense_lineStrings.csv'
defense_lineStrings_filename = 'C:\Users\Mitch\PycharmProjects\BDB_revisit\Data\defense_lineStrings.csv'

offensee_lookup_filename = 'C:\Users\Mitch\PycharmProjects\BDB_revisit\Data\offense_lookup.csv'
defense_lookup_filename = 'C:\Users\Mitch\PycharmProjects\BDB_revisit\Data\defense_lookup.csv'

# can now use the reference gameId2row.csv and read_csv() with skip rows and nrows to read in the specific game based on
# gameId then find playId within those tibbles using dplyr

# then need to reshape it with dplyr again probably in a form to apply ggplot and transition_manual