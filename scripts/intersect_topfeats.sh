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


#### Extract intersection of top discriminant biomarkers from rf_j and rf_rSNF, producing Venn diagram of intersection and lists with intersected biomarkers ####

# File with parameters, separated by tabular space
paramList=$1
read -a params <<<$(awk "NR==1" $paramList)

# Configuration file of RF on juxtaposed datasets (This is the *.log output of sklearn_rf_training_fixrank.py in rf_j)
configFile1=${params[0]}
# Configuration file of RF on juxtaposed datasets, with rSNF-ranked features (This is the *.log output of sklearn_rf_training_fixrank.py in rf_rSNF)
configFile2=${params[1]}
# Output file (.png extension for Venn diagram)
oFile=${params[2]}
# Path with scripts for intersection
sPath=${params[3]}
# Title of the Venn diagram with rf_j biomarkers
t1=${params[4]}
# Title of the Venn diagram with rf_rSNF biomarkers
t2=${params[5]}

# Intersect top biomarkers
python ${sPath}/intersect_biomarkers.py ${configFile1} ${configFile2} ${oFile} --title1 ${t1} --title2 ${t2} 
# Extract intersected features (from rf_j and rf_rSNF) from juxtaposed datasets
oPath=`dirname ${oFile}`
#cut -f1 ${oPath}/Intersection_${t1}_${t2}.txt | tail -n+2 > ${oPath}/rSNFi_feats.txt
cut -f1 ${oPath}/Intersection_${t1}_${t2}.txt > ${oPath}/rSNFi_feats.txt