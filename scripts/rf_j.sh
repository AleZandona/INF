#!/bin/bash

## This code is written by Alessandro Zandona' <zandona@fbk.eu>.
## Requires Python >= 2.7, mlpy >= 3.5


#### Perform Random Forest (RF) on juxtaposed dataset ####

# File with parameters, separated by tabular space
paramList=$1
read -a params <<<$(awk "NR==1" $paramList)

## Full paths required ##
# Data table to train RF (samples X variables) - 70% of original dataset
dataFile=${params[0]}
# Labels file (one column with phenotypes as binary labels, no header)
labFile=${params[1]}
# Data table to validate RF (samples X variables) - 30% of original dataset
validFile=${params[2]}
# Labels file for validation dataset (one column with phenotypes as  binary labels, no header)
validLabFile=${params[3]}
# Output folder
oPath=${params[4]}
# Path with machine-learning scripts
sPath=${params[5]}

#### RF training ####

# Create output folder, if not present
if [ ! -d ${oPath} ]
then
	mkdir ${oPath}
fi

# RF classifier training
python ${sPath}/sklearn_rf_training_fixrank.py ${dataFile} ${labFile} ${oPath}


#### RF Random labels (Shuffling phenotype labels) ####
if [ ! -d ${oPath}/random_labels ]
then
	mkdir ${oPath}/random_labels
fi
# RF classifier training with random labels
python ${sPath}/sklearn_rf_training_fixrank.py ${dataFile} ${labFile} ${oPath}/random_labels --random


#### RF Random ranking (Shuffling ranking of biomarkers) ####
if [ ! -d ${oPath}/random_ranking ]
then
	mkdir ${oPath}/random_ranking
fi
# RF classifier training with random ranking
python ${sPath}/sklearn_rf_training_fixrank.py ${dataFile} ${labFile} ${oPath}/random_ranking --ranking random


#### RF validation ####

if [ ! -d ${oPath}/validation ]
then
	mkdir ${oPath}/validation
fi
logFile=`ls ${oPath}/*.log`
python ${sPath}/sklearn_rf_validation_writeperf.py ${logFile} ${validFile} ${oPath}/validation --tslab ${validLabFile}