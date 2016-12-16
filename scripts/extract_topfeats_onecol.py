## This code is written by Marco Chierici <chierici@fbk.eu>, Alessandro Zandona' <zandona@fbk.eu>.
## Based on code previously written by Davide Albanese.

## Requires Python >= 2.7, mlpy >= 3.5


import numpy as np
import csv
import sys

__author__  = 'Marco Chierici, Alessandro Zandona' 
__date__    = '15 December 2016'

#### Extract features from a given dataset ####

def extract_feats(datafile, rankedfile, outfile):
    print locals()
    # table with feats abundances 
    data = np.loadtxt(datafile, delimiter = '\t', dtype = str)
    # feats abundances (no names of samples, no header)
    data_ab = data[1:,1:].astype(np.float)

    rank = np.loadtxt(rankedfile, delimiter = '\t', skiprows = 1, dtype = str)
    # number of features in the list
    nf_list = rank.shape
    if len(nf_list)>1:
        feats = rank[:, 0]
        top_feats = feats #[0:nfeat]
    else:
        top_feats = rank



    print top_feats.shape
    # extract top features from table with abundances of all features
    idx = []
    nfeat = len(top_feats)
    for i in range(0, nfeat):
        if top_feats[i] in data[0,:].tolist():
            idx.append(data[0,:].tolist().index(top_feats[i]))
        else:
            print top_feats[i]

    # considering samples names in the new table
    idx = [0] + idx
    sel_feats = data[:, idx]

    # write new table
    outw = open(outfile, 'w')
    writer = csv.writer(outw, delimiter = '\t', lineterminator = '\n')
    for i in range(0, len(sel_feats[:,0])):
        writer.writerow(sel_feats[i,:])

    outw.close()


if __name__ == "__main__":
    if not len(sys.argv) == 4:
        print "Usage: %prog data.txt rankingfile outdata.txt"
        sys.exit(1)

    # file with all feats abundances (where selected feats have to be picked from)
    datafile = sys.argv[1]
    # file with ranked features
    rankedfile = sys.argv[2]
    # file with abundances of the only selected features
    outfile = sys.argv[3]

    extract_feats(datafile, rankedfile, outfile)