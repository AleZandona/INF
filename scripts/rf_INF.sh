#!/bin/bash

## This code is written by Alessandro Zandona' <zandona@fbk.eu>.
## Requires Python >= 2.7, mlpy >= 3.5


#### Random Forest on (INF) reduced dataset ####

# File with parameters, separated by tabular space
paramList=$1
read -a params <<<$(awk "NR==1" $paramList)

# Data table to train RF (samples X variables) - 70% of original dataset
dataFile=${params[0]}
# Labels file (one column with phenotypes as binary labels, no header)
labFile=${params[1]}
# Intersection of top discriminant biomarkers from rf_j and rf_rSNF
rSNFiFeats=${params[2]}
# Data table to validate RF (samples X variables) - 30% of original dataset
validFile=${params[3]}
# Labels file for validation dataset (one column with phenotypes as  binary labels, no header)
validLabFile=${params[4]}
# Output folder
oPath=${params[5]}
# Path with machine-learning scripts
sPath=${params[6]}

# Reduce training dataset on biomarkers intersection (rf_j and rf_rSNF)
data_rsnfi_tmp=`basename ${dataFile} .txt`
data_rsnfi=${data_rsnfi_tmp}_rSNFi_feats.txt
dataPath=`dirname ${dataFile}` 
python ${sPath}/extract_topfeats_onecol.py ${dataFile} ${rSNFiFeats} ${dataPath}/${data_rsnfi}

#### RF training ####

# Create output folder, if not present
if [ ! -d ${oPath} ]
then
	mkdir ${oPath}
fi

# RF classifier training on INF-reduced dataset
python ${sPath}/sklearn_rf_training_fixrank.py ${dataPath}/${data_rsnfi} ${labFile} ${oPath} --plot


#### RF Random labels (Shuffling phenotype labels) ####
if [ ! -d ${oPath}/random_labels ]
then
	mkdir ${oPath}/random_labels
fi
# RF classifier training with random labels
python ${sPath}/sklearn_rf_training_fixrank.py ${dataPath}/${data_rsnfi} ${labFile} ${oPath}/random_labels --plot --random


#### RF Random ranking (Shuffling ranking of biomarkers) ####
if [ ! -d ${oPath}/random_ranking ]
then
	mkdir ${oPath}/random_ranking
fi
# RF classifier training with random ranking
python ${sPath}/sklearn_rf_training_fixrank.py ${dataPath}/${data_rsnfi} ${labFile} ${oPath}/random_ranking --ranking random --plot


#### RF Validation ####

if [ ! -d ${oPath}/validation ]
then
	mkdir ${oPath}/validation
fi
logFile=`ls ${oPath}/*.log`
python ${sPath}/sklearn_rf_validation_writeperf.py ${logFile} ${validFile} ${oPath}/validation --tslab ${validLabFile}
