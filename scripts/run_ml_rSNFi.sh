#!/bin/bash

## This code is written by Alessandro Zandona' <zandona@fbk.eu>.
## Requires Python >= 2.7, mlpy >= 3.5, R >= 3.2.3


# List of parameters files 
paramFile_list=$1
read -a params <<<$(awk "NR==1" $paramFile_list)
# Path to directory with scripts to run
sPath=$2


##########################################
# STEP 1 - RF on juxtaposed dataset (rf_j)
##########################################
echo '#################################'
echo '############ rf-j ###############'
echo '#################################'
# Parameters file for rf_j.sh 
paramFile_rf=${params[0]}
#${sPath}/rf_j.sh ${paramFile_rf}


###############
# STEP 2 - rSNF
###############
echo '#################################'
echo '############ rSNF ###############'
echo '#################################'
# Parameters file for rSNF.sh 
paramFile_rsnf=${params[1]}
#${sPath}/rSNF.sh ${paramFile_rsnf}


##############################################################
# STEP 3 - RF on juxtaposed dataset, with rSNF-ranked features
##############################################################
echo '#################################'
echo '########### rf-rSNF #############'
echo '#################################'
# Parameters file for rf_rSNF.sh
paramFile_rf_rsnf=${params[2]}
#${sPath}/rf_rSNF.sh ${paramFile_rf_rsnf}


#########################################################
# STEP 4 - intersect top biomarkers from rf_j and rf_rSNF
#########################################################
echo '#################################'
echo '########## intersect ############'
echo '#################################'
# Parameters file for intersect_topfeats.sh
paramFile_inter_rf=${params[3]}
${sPath}/intersect_topfeats.sh ${paramFile_inter_rf}


######################################################################################
# STEP 5 - RF on reduced dataset with intersection of biomarkers from rf_j and rf_rSNF 
######################################################################################
echo '#################################'
echo '############ rSNFi ##############'
echo '#################################'
# Parameters file for rf_rSNFi.sh
paramFile_rf_rsnfi=${params[4]}
${sPath}/rf_rSNFi.sh ${paramFile_rf_rsnfi}