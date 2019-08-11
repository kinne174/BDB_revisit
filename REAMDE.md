# Big Data Bowl Revisited

The intention of this code is to revisit the data provided by the Big
Data Bowl and to try to do something that was not requested as part of
the three areas originally proposed. 

I try to predict as early as possible the route being run by the receiver
and the predicted path of the receiver. The goal is to make this player 
based so attempting to find certain characteristics about specific 
receivers combined with overall characteristics of all receivers. I
also want to differentiate between whether a play is a run or a pass
as soon as possible (see if I can beat when the ball is being handed
off especially in a draw play). 

Expected output would be a timestep by timestep prediction percentage
of which routes is being run. Also at each timestep a "heatmap" of 
where I believe the receiver is most likely to run to next.

Still to be determined is the analysis method used. Currently I am
in data preprocessing to get all the info I believe I'll need.