#!/bin/bash

## This code is written by Alessandro Zandona' <zandona@fbk.eu>.
## Requires R >= 3.2.3


#### Run rSNF to integrate two datasets with different data types and produce a ranked list of integrated features ####

# File with parameters, separated by tabular space
paramList=$1
read -a params <<<$(awk "NR==1" $paramList)

# First dataset to integrate (samples X variables) - i.e., bacteria
dataFile1=${params[0]}
# Second dataset to integrate (samples X variables) - i.e., fungi
dataFile2=${params[1]}
# Labels file (one column with phenotypes as binary labels, no header)
labFile=${params[2]}
# Output file for rSNF-ranked list of features (full path)
oFile=${params[3]}
# Path to SNFtools, that is directory with SNF scripts from [Wang et al, Nature Methods, 2014]. NB: snf_integration_tuning.R must be kept in this directory
snfPath=${params[4]}
# Path with script for SNF integration
sPath=${params[5]}

# Run integration of datasets, followed by our rSNF feature ranking method (by spectral clustering)
Rscript ${sPath}/snf_integration.R --d1 ${dataFile1} --d2 ${dataFile2} --lab ${labFile} --outf ${oFile} --scriptDir ${snfPath} --clust spectral