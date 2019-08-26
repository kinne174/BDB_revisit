import os
import glob
import pandas as pd

def tracking_sort_helper(filename):
    assert isinstance(filename, str)
    period = filename.index('.')
    first_underscore = filename.index('_')
    second_underscore = filename[first_underscore+1:].index('_')
    gameId = filename[first_underscore+1 + second_underscore+1:period]
    return gameId

# grab tracking filenames
old_header = 'C:/Users/Mitch/Documents/UofM/Fall 2018/NFL/Data'
tracking_filenames = glob.glob(os.path.join(old_header, 'tracking_gameId_*'))

# grab offense
offense_lookup_filename = 'Data/offense_lookup.csv'

# get unique gameIds from offense lookup
offense_lookup = pd.read_csv(offense_lookup_filename)

unique_offense_gameIds = offense_lookup['gameId'].unique().tolist()

tracking_gameIds = [int(tracking_sort_helper(f)) for f in tracking_filenames]

shared_gameIds = set(unique_offense_gameIds).intersection(set(tracking_gameIds))

defense_lookup_filename = 'Data/defense_lookup.csv'
defense_lineStrings_filename = 'Data/defense_lineStrings.csv'
ball_lineStrings_filename = 'Data/ball_lineStrings.csv'
if os.path.exists(defense_lookup_filename):
    out_lookup = pd.read_csv(defense_lookup_filename)
else:
    out_lookup = pd.DataFrame()
if os.path.exists(defense_lineStrings_filename):
    out_lineStrings = pd.read_csv('Data/defense_lineStrings.csv')
else:
    out_lineStrings = pd.DataFrame()
if os.path.exists(ball_lineStrings_filename):
    out_ball = pd.read_csv(ball_lineStrings_filename)
else:
    out_ball = pd.DataFrame()

for fn in tracking_filenames:
    current_gameId = int(tracking_sort_helper(fn))
    if current_gameId not in shared_gameIds:
        continue

    # if not out_lookup.empty:
    #     out_lookup_gameIds = out_lookup['gameId'].tolist()
    #     if current_gameId in out_lookup_gameIds:
    #         continue

    if not out_ball.empty:
        out_ball_uniqueIds = out_ball['uniqueId'].tolist()
        out_ball_gameIds = [int(ui[:9]) for ui in out_ball_uniqueIds]
        if current_gameId in out_ball_gameIds:
            continue

    current_tracking_file = pd.read_csv(fn)
    current_lineStrings = {'uniqueId': [], 'x': [], 'y': [], 'timestep': []}
    current_lookup = {'uniqueId': [], 'gameId': [], 'playId': [], 'nflId': [], 'position': []}
    current_ball_dict = {'uniqueId': [], 'x': [], 'y': [], 'timestep': []}

    all_play_Ids = offense_lookup.loc[offense_lookup['gameId'] == current_gameId, 'playId'].unique().tolist()

    for play_Id in all_play_Ids:
        reduced_tracking_file = current_tracking_file.loc[(current_tracking_file['playId'] == play_Id) &
                                                           ((current_tracking_file['position'] == 'SS') |
                                                          (current_tracking_file['position'] == 'FS') |
                                                          (current_tracking_file['position'] == 'ILB') |
                                                          (current_tracking_file['position'] == 'OLB') |
                                                          (current_tracking_file['position'] == 'MLB') |
                                                          (current_tracking_file['position'] == 'CB'))]

        ball_tracking_file = current_tracking_file.loc[(current_tracking_file['playId'] == play_Id) &
                                                       (current_tracking_file['position'] == 'ball')]

        ball_snap_frame_list = reduced_tracking_file.loc[reduced_tracking_file['event'] == 'ball_snap',
                                                         'frame.id'].mode().tolist()
        assert len(ball_snap_frame_list) == 1
        ball_snap_frame = int(ball_snap_frame_list[0])

        outcome_frame_list = reduced_tracking_file.loc[(reduced_tracking_file['event'] == 'pass_outcome_incomplete') |
                                                       (reduced_tracking_file['event'] == 'pass_outcome_caught') |
                                                       (reduced_tracking_file['event'] == 'pass_outcome_interception') |
                                                       (reduced_tracking_file['event'] == 'pass_outcome_touchdown') |
                                                       (reduced_tracking_file['event'] == 'qb_sack'), 'frame.id'].unique().tolist()
        # assert len(outcome_frame_list) == 1
        outcome_frame = int(min(outcome_frame_list))

        end_frame = ball_snap_frame + 50 if outcome_frame - ball_snap_frame > 50 else outcome_frame

        out_tracking_file = reduced_tracking_file.loc[(reduced_tracking_file['frame.id'] >= ball_snap_frame) &
                                                      (reduced_tracking_file['frame.id'] <= end_frame),
                                                      ['x', 'y', 'nflId', 'playId', 'position']]

        out_ball_file = ball_tracking_file.loc[(ball_tracking_file['frame.id'] >= ball_snap_frame) &
                                               (ball_tracking_file['frame.id'] <= end_frame),
                                               ['x', 'y', 'playId']]

        # for _, row in out_tracking_file.iterrows():
        #     current_uniqueId = '-'.join([str(current_gameId), str(row['playId']), str(int(row['nflId']))])
        #
        #     if current_uniqueId not in current_lookup['uniqueId']:
        #         current_lookup['uniqueId'].append(current_uniqueId)
        #         current_lookup['gameId'].append(current_gameId)
        #         current_lookup['playId'].append(row['playId'])
        #         current_lookup['nflId'].append(row['nflId'])
        #         current_lookup['position'].append(row['position'])
        #         timestep = 0
        #     else:
        #         timestep += 1
        #
        #     current_lineStrings['uniqueId'].append(current_uniqueId)
        #     current_lineStrings['x'].append(row['x'])
        #     current_lineStrings['y'].append(row['y'])
        #     current_lineStrings['timestep'].append(timestep)

        for _, row in out_ball_file.iterrows():
            current_ballId = '-'.join([str(current_gameId), str(int(row['playId'])), 'ball'])

            if current_ballId not in current_ball_dict['uniqueId']:
                timestep = 0
            else:
                timestep += 1

            current_ball_dict['uniqueId'].append(current_ballId)
            current_ball_dict['x'].append(row['x'])
            current_ball_dict['y'].append(row['y'])
            current_ball_dict['timestep'].append(timestep)

    out_ball = out_ball.append(pd.DataFrame.from_dict(current_ball_dict), ignore_index=True)
    out_ball.to_csv(ball_lineStrings_filename, index=False)

    # out_lineStrings = out_lineStrings.append(pd.DataFrame.from_dict(current_lineStrings), ignore_index=True)
    # out_lookup = out_lookup.append(pd.DataFrame.from_dict(current_lookup), ignore_index=True)
    #
    # out_lineStrings.to_csv(defense_lineStrings_filename, index=False)
    # out_lookup.to_csv(defense_lookup_filename, index=False)


















