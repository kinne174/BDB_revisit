library(tidyverse)

offense_lineStrings_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/offense_lineStrings.csv'

all_gameIds = c()
offense_lineStrings_indices = c()

con  <- file(offense_lineStrings_filename, open = "r")
i = 0
while (length(oneLine <- readLines(con, n = 1)) > 0) {
  myLine <- unlist((strsplit(oneLine, ",")))
  if (i == 0){
    header = myLine
  }else{
    current_gameId = substr(myLine[1], 1, 10)
    if (!(current_gameId %in% all_gameIds)) {
      all_gameIds = append(all_gameIds, current_gameId)
      offense_lineStrings_indices = append(offense_lineStrings_indices, i)
    }
  }
  i = i + 1
} 
close(con)

defense_lineStrings_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/defense_lineStrings.csv'

all_gameIds = c()
defense_lineStrings_indices = c()

con  <- file(defense_lineStrings_filename, open = "r")
i = 0
while (length(oneLine <- readLines(con, n = 1)) > 0) {
  myLine <- unlist((strsplit(oneLine, ",")))
  if (i == 0){
    header = myLine
  }else{
    current_gameId = substr(myLine[1], 1, 10)
    if (!(current_gameId %in% all_gameIds)) {
      all_gameIds = append(all_gameIds, current_gameId)
      defense_lineStrings_indices = append(defense_lineStrings_indices, i)
    }
  }
  i = i + 1
} 
close(con)

offensee_lookup_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/offense_lookup.csv'

all_gameIds = c()
offense_lookup_indices = c()

con  <- file(offensee_lookup_filename, open = "r")
i = 0
while (length(oneLine <- readLines(con, n = 1)) > 0) {
  myLine <- unlist((strsplit(oneLine, ",")))
  if (i == 0){
    header = myLine
  }else{
    current_gameId = substr(myLine[1], 1, 10)
    if (!(current_gameId %in% all_gameIds)) {
      all_gameIds = append(all_gameIds, current_gameId)
      offense_lookup_indices = append(offense_lookup_indices, i)
    }
  }
  i = i + 1
} 
close(con)

defense_lookup_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/defense_lookup.csv'

all_gameIds = c()
defense_lookup_indices = c()

con  <- file(defense_lookup_filename, open = "r")
i = 0
while (length(oneLine <- readLines(con, n = 1)) > 0) {
  myLine <- unlist((strsplit(oneLine, ",")))
  if (i == 0){
    header = myLine
  }else{
    current_gameId = substr(myLine[1], 1, 10)
    if (!(current_gameId %in% all_gameIds)) {
      all_gameIds = append(all_gameIds, current_gameId)
      defense_lookup_indices = append(defense_lookup_indices, i)
    }
  }
  i = i + 1
} 
close(con)

ball_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/ball_lineStrings.csv'

all_gameIds = c()
ball_indices = c()

con  <- file(ball_filename, open = "r")
i = 0
while (length(oneLine <- readLines(con, n = 1)) > 0) {
  myLine <- unlist((strsplit(oneLine, ",")))
  if (i == 0){
    header = myLine
  }else{
    current_gameId = substr(myLine[1], 1, 10)
    if (!(current_gameId %in% all_gameIds)) {
      all_gameIds = append(all_gameIds, current_gameId)
      ball_indices = append(ball_indices, i)
    }
  }
  i = i + 1
} 
close(con)

out_tibble = tibble(all_gameIds, offense_lineStrings_indices, defense_lineStrings_indices, offense_lookup_indices, defense_lookup_indices, ball_indices)

gameId2row_filename = 'C:/Users/Mitch/PycharmProjects/BDB_revisit/Data/gameId2row.csv'
write_csv(out_tibble, gameId2row_filename)






