## This code is written by Alessandro Zandona' <zandona@fbk.eu>.

## Requires Python >= 2.7, mlpy >= 3.5


from __future__ import division
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib_venn as pltv
import sys
import csv
import os.path
import argparse
import ConfigParser
from distutils.version import StrictVersion

parser = argparse.ArgumentParser(description='Find the intersection between feature lists and produce Venn diagrams.')
parser.add_argument('CONFIGFILE1', type=str, help='Training experiment configuration file 1 (with info about number of top discriminant features)')
parser.add_argument('CONFIGFILE2', type=str, help='Training experiment configuration file 2 (with info about number of top discriminant features)')
parser.add_argument('--title1', type=str, default='List_1', help='Name for first diagram (default: %(default)s)')
parser.add_argument('--title2', type=str, default='List_2', help='Name for second diagram (default: %(default)s)')
parser.add_argument('--configFile3', type=str, default='NO', help='Third configuration file - optional (default: %(default)s)')
parser.add_argument('--title3', type=str, default='List_3', help='Name for third diagram (default: %(default)s)')
parser.add_argument('OUTFILE', type=str, help='Output file for Venn diagram plot.')

__author__  = 'Alessandro Zandona' 
__date__    = '15 December 2016'

if len(sys.argv)==1:
    parser.print_help()
    sys.exit(1)

args = parser.parse_args()
CONFIGFILE1 = vars(args)['CONFIGFILE1']
CONFIGFILE2 = vars(args)['CONFIGFILE2']
OUTFILE = vars(args)['OUTFILE']
title1 = vars(args)['title1']
title2 = vars(args)['title2']
configfile3 = vars(args)['configFile3']
title3 = vars(args)['title3']

config = ConfigParser.RawConfigParser()
config.read(CONFIGFILE1)
if not config.has_section('INPUT'):
    print "%s is not a valid configuration file." % CONFIGFILE1
    sys.exit(3)

RANK = config.get("OUTPUT", "Borda")
NFEATS = config.getint("OUTPUT", "N_feats")

# Feature lists
fl_1 = np.loadtxt(RANK, dtype=str, delimiter='\t', skiprows=1)
# Features name
feats1 = fl_1[:NFEATS, 1]
# Convert lists into sets
feats1_set = set(feats1)

config.read(CONFIGFILE2)
if not config.has_section('INPUT'):
    print "%s is not a valid configuration file." % CONFIGFILE2
    sys.exit(3)

RANK = config.get("OUTPUT", "Borda")
NFEATS = config.getint("OUTPUT", "N_feats")

# Feature lists
fl_2 = np.loadtxt(RANK, dtype=str, delimiter='\t', skiprows=1)
# Features name
feats2 = fl_2[:NFEATS, 1]
# Convert lists into sets
feats2_set = set(feats2)

if (configfile3 != 'NO'):
   config.read(configfile3)
   if not config.has_section('INPUT'):
      print "%s is not a valid configuration file." % CONFIGFILE2
      sys.exit(3)

   RANK = config.get("OUTPUT", "Borda")
   NFEATS = config.getint("OUTPUT", "N_feats")

   # Feature lists
   fl_3 = np.loadtxt(RANK, dtype=str, delimiter='\t', skiprows=1)
   # Features name
   feats3 = fl_3[:NFEATS, 1]
   # Convert lists into sets 
   feats3_set = set(feats3)


# Intersection between lists
f1f2 = feats1_set.intersection(feats2_set)
if (configfile3 != 'NO'):
   f1f3 = feats1_set.intersection(feats3_set)
   f2f3 = feats2_set.intersection(feats3_set)

# associate to each common feature the position in each lists
outFile_f1f2=os.path.join(os.path.dirname(OUTFILE),'Intersection_%s_%s.txt' %(title1,title2))
outw=open(outFile_f1f2, 'w')
writer = csv.writer(outw, delimiter = '\t', lineterminator = '\n')
writer.writerow(['Feature', 'Position in %s' %title1, 'Postition in %s' %title2])
for i in range(len(list(f1f2))):
   # current feature in intersection
   interF = list(f1f2)[i]
   # position of current feature in first list
   idx_list1 = np.where(feats1==interF)[0][0]
   # position of current feature in second list
   idx_list2 = np.where(feats2==interF)[0][0]
   writer.writerow([list(f1f2)[i], idx_list1+1, idx_list2+1])
outw.close()

if (configfile3 != 'NO'):
   # associate to each common feature the position in each lists
   outFile_f1f3=os.path.join(os.path.dirname(OUTFILE),'Intersection_%s_%s.txt' %(title1,title3))
   outw=open(outFile_f1f3, 'w')
   writer = csv.writer(outw, delimiter = '\t', lineterminator = '\n')
   writer.writerow(['Feature', 'Position in %s '%title1, 'Postition in %s ' %title3])
   for i in range(len(list(f1f3))):
      # current feature in intersection
      interF = list(f1f3)[i]
      # position of current feature in first list
      idx_list1 = np.where(feats1==interF)[0][0]
      # position of current feature in second list
      idx_list3 = np.where(feats3==interF)[0][0]
      writer.writerow([list(f1f3)[i], idx_list1+1, idx_list3+1])
   outw.close()

   outFile_f2f3=os.path.join(os.path.dirname(OUTFILE),'Intersection_%s_%s.txt' %(title2,title3))
   outw=open(outFile_f2f3, 'w')
   writer = csv.writer(outw, delimiter = '\t', lineterminator = '\n')
   writer.writerow(['Feature', 'Position in %s '%title2, 'Postition in %s ' %title3])
   for i in range(len(list(f2f3))):
      # current feature in intersection
      interF = list(f2f3)[i]
      # position of current feature in first list
      idx_list2 = np.where(feats2==interF)[0][0]
      # position of current feature in second list
      idx_list3 = np.where(feats3==interF)[0][0]
      writer.writerow([list(f2f3)[i], idx_list2+1, idx_list3+1])
   outw.close()

# plot Venn diagrams
if (configfile3 != 'NO'):
   v3_inter = pltv.venn3([feats1_set, feats2_set, feats3_set], (title1, title2, title3))
   plt.title('Intersection of top discriminant features from %s, %s and %s' %(title1,title2,title3))
else:
   v2_inter = pltv.venn2([feats1_set, feats2_set], (title1, title2))
   plt.title('Intersection of top discriminant features from %s and %s' %(title1,title2))

plt.savefig(OUTFILE)
plt.close()