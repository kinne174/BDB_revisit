import numpy as np
import os
import glob
import json
from collections import namedtuple
from string_to_xy import s2xy
import pandas as pd

# grab files with route labels from previous go through
old_header = 'C:/Users/Mitch/Documents/UofM/Fall 2018/NFL/Data'
all_plays_filename = os.path.join(old_header, 'plays.csv')
all_players_filename = os.path.join(old_header, 'players.csv')
all_players = pd.read_csv(all_players_filename)

def extract_info_from_routescsv(csv_filename):
    assert isinstance(csv_filename, str)
    # output dict with keys-> unique Ids and values -> namedtuple(gameId, playId, nflId, routeLabel, Linestring)
    routesDoc = namedtuple('routesDoc', 'gameId playId nflId routeLabel lineString')

    route_info_dict = {}

    # first_underscore = csv_filename.find('_')
    # first_period = csv_filename.find('.')
    gameId = csv_sort_helper(csv_filename)

    # route_csv = np.loadtxt(csv_filename, delimiter=',', skiprows=1)
    route_csv = pd.read_csv(csv_filename)

    nflId = 0
    playId = 1
    LineString = 2
    position = 3
    route = 4

    for i in range(route_csv.shape[0]):
        current_nflId = route_csv.iloc[i, nflId]
        current_playId = route_csv.iloc[i, playId]
        current_linestring = route_csv.iloc[i, LineString]
        current_route = route_csv.iloc[i, route]

        current_uniqueID = '-'.join([str(gameId), str(current_playId), str(current_nflId)])

        route_info_dict[current_uniqueID] = routesDoc(gameId=gameId, playId=current_playId, nflId=current_nflId,
                                                      routeLabel=current_route, lineString=current_linestring)

    return route_info_dict


def extract_info_from_json(json_filename):
    # output dict with keys -> unique Ids and values -> namedtuple(gameId, playId, leftOrRight, intended, position, routeLabel, height, weight)

    playerDoc = namedtuple('playerDoc', 'gameId, playId, leftOfBall intended position routeLabel height weight')
    player_info_dict = {}

    with open(json_filename, 'r') as json_file:
        current_play_list = json.load(json_file)
        gameId = json_sort_helper(json_filename)

        for i in range(len(current_play_list)):
            current_dict = current_play_list[i]
            if len(current_dict) == 1:
                continue

            current_playId = current_dict['playId']
            for j in range(len(current_dict['all_receivers'])):
                current_receiver = current_dict['all_receivers'][j]

                current_left = current_receiver[2] > 0 # positive number here means to the left so left of ball is true if this is positive
                current_intendend = bool(current_receiver[4])
                current_position = current_receiver[0]
                current_routeLabel = current_receiver[1]
                current_height = current_receiver[5]
                current_weight = current_receiver[6]

                current_uniqueId = '-'.join([str(gameId), str(current_playId), str(j)])
                player_info_dict[current_uniqueId] = playerDoc(gameId=gameId, playId=current_playId,
                                                               leftOfBall=current_left, intended=current_intendend,
                                                               position=current_position, routeLabel=current_routeLabel,
                                                               height=current_height, weight=current_weight)

    return player_info_dict


def extract_info_from_(csv_filename, json_filename, all_players):
    # output dict with keys-> unique Ids and values-> namedtuple(gameId, playId, nflId, position, leftOrRight, routeLabel, intended, Linestring)

    # before entering assert that the gameIds are the same
    route_dict = extract_info_from_routescsv(csv_filename)
    player_dict = extract_info_from_json(json_filename)

    # all_plays = np.loadtxt(all_plays_filename, delimiter=',', skiprows=1)

    # nflId = 0
    # PositionAbbr = 3
    # Height_cm = 10
    # Weight = 8

    outDoc = namedtuple('outDoc', 'gameId playId nflId position leftOfBall routeLabel intended lineString')
    out_dict = {}

    # assert len(route_dict) == len(player_dict) # this isn't necessarily true since I had to add in some players to get to 5 sometimes

    all_route_playIds = sorted(np.unique([val.playId for val in route_dict.values()]))
    all_player_playIds = sorted(np.unique([val.playId for val in player_dict.values()]))

    # assert len(all_route_playIds) == len(all_player_playIds)
    # assert all([rId == pId for rId, pId in zip(all_route_playIds, all_player_playIds)])

    assert all([pId in all_route_playIds for pId in all_player_playIds])

    lookup_height = {}
    lookup_weight = {}

    for playId in all_player_playIds:
        # current_r_heights = []
        # current_r_weights = []
        current_p_heights = []
        current_p_weights = []

        current_player_keys = [k for k, v in player_dict.items() if v.playId == playId]
        current_route_keys = [k for k, v in route_dict.items() if v.playId == playId]

        # go through each of these and see which ones match up based on nflId of player_dict and height/weight/position
        # of route_dict, then combine relevant areas into one uniqueId key and output that to be added to the new dataset
        for cpk in current_player_keys:
            current_p_heights.append(player_dict[cpk].height)
            current_p_weights.append(player_dict[cpk].weight)

        for crk in current_route_keys:
            crk_nflId = route_dict[crk].nflId

            if crk_nflId in lookup_height and crk_nflId in lookup_weight:
                current_r_height = lookup_height[crk_nflId]
                current_r_weight = lookup_weight[crk_nflId]
            else:
                # find the height and weight of nflId within all_plays
                # temp_height = all_players.iloc[np.where(all_players.iloc[:, nflId] == crk_nflId), Height_cm]
                # temp_weight = all_players.iloc[np.where(all_players.iloc[:, nflId] == crk_nflId), Weight]

                current_r_height = float(all_players.loc[all_players['nflId'] == crk_nflId, 'Height_cm'])
                current_r_weight = float(all_players.loc[all_players['nflId'] == crk_nflId, 'Weight'])

                # current_r_height = temp_height
                # current_r_weight = temp_weight

                lookup_height[crk_nflId] = current_r_height
                lookup_weight[crk_nflId] = current_r_weight

            all_heights, = np.where(np.array(current_p_heights) == current_r_height)
            all_weights, = np.where(np.array(current_p_weights) == current_r_weight)

            assert len(all_heights) > 0
            assert len(all_weights) > 0

            if len(all_heights) == 1 and len(all_weights) == 1:
                current_p_key = current_player_keys[int(all_heights)]
            else:
                intersecting_index = set(all_heights).intersection(set(all_weights))
                if len(intersecting_index) > 1:
                    # do something here to randomize selection
                    intersecting_index = [list(intersecting_index)[np.random.randint(low=0,
                                                                                        high=len(intersecting_index))]]

                assert len(intersecting_index) == 1

                current_p_key = current_player_keys[int(list(intersecting_index)[0])]

            # height_index = current_p_heights.index(current_r_height)
            # weight_index = current_p_weights.index(current_r_weight)
            #
            # if height_index == weight_index:
            #     current_p_key = current_player_keys[height_index]
            # else:


            out_gameId = int(route_dict[crk].gameId)
            out_playId = route_dict[crk].playId
            out_nflId = crk_nflId
            out_position = player_dict[current_p_key].position
            out_leftOfBall = player_dict[current_p_key].leftOfBall
            out_routeLabel = route_dict[crk].routeLabel
            out_intended = player_dict[current_p_key].intended
            out_lineString = route_dict[crk].lineString

            uniqueId = crk

            out_dict[uniqueId] = outDoc(out_gameId, out_playId, out_nflId, out_position, out_leftOfBall, out_routeLabel,
                                   out_intended, out_lineString)

    return out_dict


# sort helpers
def csv_sort_helper(x):
    first_underscore = x.find('_')
    first_period = x.find('.')
    gameId = x[first_underscore+1:first_period]
    return gameId

def json_sort_helper(x):
    first_underscore = x.find('_')
    first_period = x.find('.')
    second_underscore = x[first_underscore+1:].find('_')
    gameId = x[first_underscore+1+second_underscore+1:first_period]
    return gameId

# create a dictionary to keep track of individual game-play-player information using the unique Id based on the
# concatenation of those three

game_play_player_dict = {}
lookup_filename = 'Data/lookup.csv'
lookup_filename_temp = 'Data/lookup_temp.csv'
lineString_dict = {}
linesString_filename = 'Data/lineStrings.csv'

if not os.path.exists(lookup_filename):
    raise Exception('This file does not exist: {}'.format(lookup_filename))

if not os.path.exists(linesString_filename):
    raise Exception('This file does not exist: {}'.format(linesString_filename))

# route .csv's contain information about the play Id, the player Id, route LineString and route label
routes_filenames = glob.glob(os.path.join(old_header, 'Routes_*'))

# json filenames contains information about where the receiver was lined up and whether they were the intended
# receiver or not
json_filenames = glob.glob(os.path.join(old_header, '*.json'))

assert len(routes_filenames) == len(json_filenames)

# go through each filenames and make sure they are the same before feeding into extract_info_from_
routes_filenames.sort(key=csv_sort_helper)
json_filenames.sort(key=json_sort_helper)

for rf, jf in zip(routes_filenames, json_filenames):
    gameId_rf = csv_sort_helper(rf)
    gameId_jf = json_sort_helper(jf)
    assert gameId_rf == gameId_jf

# assert all([json_sort_helper(jf) == csv_sort_helper(rf) for jf, rf in zip(json_filenames, routes_filenames)])

# need a way in here to start and stop depending on where the file is
# uniqueId = 0
gameId = 1
# playId = 2
# nflId = 3
# position = 4
# leftOfBall = 5
# routeLabel = 6
# intended = 7

for jf, rf in zip(json_filenames, routes_filenames):
    # lookup_file = np.loadtxt(lookup_filename, delimiter=',', skiprows=1)
    lookup_file = pd.read_csv(lookup_filename)
    if not lookup_file.shape[0] == 0:
        recorded_gameIds = np.unique(lookup_file.iloc[:, gameId])

        current_gameId = int(json_sort_helper(jf))
        if current_gameId in recorded_gameIds:
            continue

    current_dict = extract_info_from_(rf, jf, all_players)

    temp_append = np.array([[k, v.gameId, v.playId, v.nflId, v.position, v.leftOfBall, v.routeLabel, v.intended]
                            for k,v in current_dict.items()])

    assert lookup_file.shape[1] == temp_append.shape[1]

    new_lookup = np.append(lookup_file, temp_append, axis=0)


    # save to the linestrings file the xy pairs
    linesString_file = pd.read_csv(linesString_filename)

    current_lineStrings = []
    for k, v in current_dict.items():
        current_xy = s2xy(v.lineString)
        temp_extend = [[k, t[0], t[1], i] for i, t in enumerate(current_xy)]
        current_lineStrings.extend(temp_extend)

    temp_append = np.array(current_lineStrings)

    assert linesString_file.shape[1] == temp_append.shape[1]

    new_lineString = np.append(linesString_file, temp_append, axis=0)

    np.savetxt(fname=lookup_filename, X=new_lookup, delimiter=',', fmt='%s',
               header='uniqueId,gameId,playId,nflId,position,leftOfBall,routeLabel,intended', comments='')

    np.savetxt(fname=linesString_filename, X=new_lineString, delimiter=',', fmt = '%s',
               header='uniqueId,x,y,timestep', comments='')

# probably come back to this later, see if I can do something with just the pass plays for now, can work on
# judging between a run and pass play later

# grab old plays file with information on whether the play was a pass/run/sack
# still not dealing with sacks since not worried about play success anymore, should be enough data points without it

# for plays that were runs get receiver route information and label them run routes

# combine run routes and pass routes

# create one database with column headers from thoughts.py

# create another database with all of the x y timestep points of the routes using the game Id, play Id, player iD info
# from above dataset