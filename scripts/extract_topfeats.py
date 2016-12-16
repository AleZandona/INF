import numpy as np
from input_output import load_data
import csv
import sys

def extract_feats(datafile, rankedfile, nfeat, outfile):
    print locals()
    # sample names, features names and table with features abundances 
    samples, features, data_ab = load_data(datafile)
    # feats abundances (no names of samples, no header)
    # data_ab = data_ab.astype(np.float)

    rank = np.loadtxt(rankedfile, delimiter = '\t', skiprows = 1, dtype = str)
    # number of features in the list
    nf_list = rank.shape
    if len(nf_list)>1:
        feats = rank[:, 1]
        top_feats = feats[0:nfeat]
    else:
        top_feats = rank[1]


    #print top_feats.shape
    # extract top features from table with abundances of all features
    idx = []
    if len(nf_list)==1:
        idx.append(features.index(top_feats))
    else:
        for i in range(0, nfeat):
            if top_feats[i] in features:
                idx.append(features.index(top_feats[i]))
            else:
                print '###### MISSING %s ######' % top_feats[i]

    # considering samples names in the new table
    sel_feats=[features[i] for i in idx]

    # write new table
    outw = open(outfile, 'w')
    writer = csv.writer(outw, delimiter = '\t', lineterminator = '\n')
    # header
    writer.writerow(['Samples']+sel_feats)
    for i in range(0, len(samples)):
        writer.writerow([samples[i]]+data_ab[i,idx].tolist())

    outw.close()


if __name__ == "__main__":
    if not len(sys.argv) == 5:
        print "Usage: %prog data.txt rankingfile nfeat outdata.txt"
        sys.exit(1)

    # file with all feats abundances (where selected feats have to be picked from)
    datafile = sys.argv[1]
    # file with ranked features
    rankedfile = sys.argv[2]
    # number of feat to extract
    nfeat = int(sys.argv[3])
    # file with abundances of the only selected features
    outfile = sys.argv[4]

    extract_feats(datafile, rankedfile, nfeat, outfile)

