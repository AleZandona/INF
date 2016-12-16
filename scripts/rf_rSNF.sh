#!/bin/bash

## This code is written by Alessandro Zandona' <zandona@fbk.eu>.

## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Requires Python >= 2.7, mlpy >= 3.5


#### Random Forest with rSNF-ranked features ####

# File with parameters, separated by tabular space
paramList=$1
read -a params <<<$(awk "NR==1" $paramList)

# Data table to train RF (samples X variables) - 70% of original dataset
dataFile=${params[0]}
# Labels file (one column with phenotypes as binary labels, no header)
labFile=${params[1]}
# Ranked features list from rSNF
rsnfFeats=${params[2]}
# Data table to validate RF (samples X variables) - 30% of original dataset
validFile=${params[3]}
# Labels file for validation dataset (one column with phenotypes as  binary labels, no header)
validLabFile=${params[4]}
# Output folder
oPath=${params[5]}
# Path with machine-learning scripts
sPath=${params[6]}

#### RF training ####

# Create output folder, if not present
if [ ! -d ${oPath} ]
then
	mkdir ${oPath}
fi

# RF classifier training by using rSNF-ranked features list
python ${sPath}/sklearn_rf_training_fixrank.py ${dataFile} ${labFile} ${oPath} --ranking rankList --rankFeats ${rsnfFeats} --plot


#### RF Random labels (Shuffling phenotype labels) ####
if [ ! -d ${oPath}/random_labels ]
then
	mkdir ${oPath}/random_labels
fi
# RF classifier training with random labels
python ${sPath}/sklearn_rf_training_fixrank.py ${dataFile} ${labFile} ${oPath}/random_labels --ranking rankList --rankFeats ${rsnfFeats} --plot --random


#### RF Validation ####

if [ ! -d ${oPath}/validation ]
then
	mkdir ${oPath}/validation
fi
logFile=`ls ${oPath}/*.log`
python ${sPath}/sklearn_rf_validation_writeperf.py ${logFile} ${validFile} ${oPath}/validation --tslab ${validLabFile}