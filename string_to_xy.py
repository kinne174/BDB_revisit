# from shapely.geometry import LineString

def s2xy(s):
    '''
    takes in a string that has been saved in a .csv and turns it back into a list of xy pairs
    :param s:
    :return: list of xy pairs
    '''

    #get only values within parenthesis
    indL = s.index('(')
    indR = s.index(')')
    onlyNumbers = s[(indL + 1):indR]
    pairs = onlyNumbers.split(',')
    split_pairs = [p.lstrip().split(' ') for p in pairs]
    split_pairs_float = [tuple(map(float, sublist)) for sublist in split_pairs]
    # ls = LineString(split_pairs_float)
    return split_pairs_float

