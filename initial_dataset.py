import numpy as np
import os
import glob
import json
from collections import namedtuple

# grab files with route labels from previous go through
old_header = 'C:/Users/Mitch/Documents/UofM/Fall 2018/NFL/Data'
all_plays_filename = os.path.join(old_header, 'plays.csv')
all_players_filename = os.path.join(old_header, 'players.csv')

def extract_info_from_routescsv(csv_filename):
    assert isinstance(csv_filename, str)
    # output dict with keys-> unique Ids and values -> namedtuple(gameId, playId, nflId, routeLabel, Linestring)
    routesDoc = namedtuple('routesDoc', 'gameId playId nflId routeLabel lineString')

    route_info_dict = {}

    first_underscore = csv_filename.find('_')
    first_period = csv_filename.find('.')
    gameId = csv_filename[first_underscore+1:first_period]

    route_csv = np.loadtxt(csv_filename, delimiter=',', skiprows=1)

    nflId = 0
    playId = 1
    LineString = 2
    position = 3
    route = 4

    for i in range(route_csv.shape[0]):
        current_nflId = route_csv[i, nflId]
        current_playId = route_csv[i, playId]
        current_linestring = route_csv[i, LineString]
        current_route = route_csv[i, route]

        current_uniqueID = '-'.join([gameId, current_playId, current_nflId])

        route_info_dict[current_uniqueID] = routesDoc(gameId=gameId, playId=current_playId, nflId=current_nflId,
                                                      routeLabel=current_route, lineString=current_linestring)

    return route_info_dict


def extract_info_from_json(json_filename):
    # output dict with keys -> unique Ids and values -> namedtuple(gameId, playId, leftOrRight, intended, position, routeLabel, height, weight)

    playerDoc = namedtuple('playerDoc', 'gameId, playId, leftOfBall intended position routeLabel height weight')
    player_info_dict = {}

    with open(json_filename, 'r') as json_file:
        current_play_list = json.load(json_file)
        gameId = current_play_list[0]['gameId']

        for i in range(len(current_play_list)):
            current_dict = current_play_list[i]

            current_playId = current_dict['playId']
            for j in range(len(current_dict['all receivers'])):
                current_receiver = current_dict['all receivers'][j]

                current_left = current_receiver[2] > 0 # positive number here means to the left so left of ball is true if this is positive
                current_intendend = bool(current_receiver[4])
                current_position = current_receiver[0]
                current_routeLabel = current_receiver[1]
                current_height = current_receiver[5]
                current_weight = current_receiver[6]

                current_uniqueId = '-'.join([gameId, current_playId, j])
                player_info_dict[current_uniqueId] = playerDoc(gameId=gameId, playId=current_playId,
                                                               leftOfBall=current_left, intended=current_intendend,
                                                               position=current_position, routeLabel=current_routeLabel,
                                                               height=current_height, weight=current_weight)

    return player_info_dict


def extract_info_from_(csv_filename, json_filename, all_plays):
    # output dict with keys-> unique Ids and values-> namedtuple(gameId, playId, nflId, position, leftOrRight, routeLabel, intended, Linestring)

    # before entering assert that the gameIds are the same
    route_dict = extract_info_from_routescsv(csv_filename)
    player_dict = extract_info_from_json(json_filename)

    # all_plays = np.loadtxt(all_plays_filename, delimiter=',', skiprows=1)

    nflId = 0
    PositionAbbr = 3
    Height = 10
    Weight = 8

    # assert len(route_dict) == len(player_dict) # this isn't necessarily true since I had to add in some players to get to 5 sometimes

    all_route_playIds = sorted(np.unique([val.playId for val in route_dict.values()]))
    all_player_playIds = sorted(np.unique([val.playId for val in player_dict.values()]))

    assert len(all_route_playIds) == len(all_player_playIds)
    assert all([rId == pId for rId, pId in zip(all_route_playIds, all_player_playIds)])

    for playId in all_route_playIds:
        current_player_keys = [k for v,k in player_dict if v.playId == playId]
        current_route_keys = [k for v,k in route_dict if v.playId == playId]

        # go through each of these and see which ones match up based on nflId of player_dict and height/weight/position
        # of route_dict, then combine relevant areas into one uniqueId key and output that to be added to the new dataset












# create a dictionary to keep track of individual game-play-player information using the unique Id based on the
# concatenation of those three

game_play_player_dict = {}

# route .csv's contain information about the play Id, the player Id, route LineString and route label
routes_filenames = glob.glob(os.path.join(old_header, 'Routes_*'))

# json filenames contains information about where the receiver was lined up and whether they were the intended
# receiver or not
json_filenames = glob.glob(os.path.join(old_header, '*.json'))

assert len(routes_filenames) == len(json_filenames)


# grab old plays file with information on whether the play was a pass/run/sack
# still not dealing with sacks since not worried about play success anymore, should be enough data points without it


# for plays that were runs get receiver route information and label them run routes

# combine run routes and pass routes

# create one database with column headers from thoughts.py

# create another database with all of the x y timestep points of the routes using the game Id, play Id, player iD info
# from above dataset