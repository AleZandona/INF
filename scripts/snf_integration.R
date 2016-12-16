## This code is written by Alessandro Zandona' <zandona@fbk.eu>.

## Requires R >= 3.2.3


suppressPackageStartupMessages(library(argparse))
library("cvTools")
library("doParallel")
library("TunePareto")
library("igraph")

parser <- ArgumentParser(description="Perform a Similarity Network Fusion analysis on two datasets [samples X features]. NB: Same samples for the 2 dataset are required!")

parser$add_argument("--d1", type="character", help = "First dataset [features X samples]")
parser$add_argument("--d2", type="character", help = "Second dataset [features X samples]")
parser$add_argument("--lab", type="character", help = "one column: labels associated to samples; NO HEADER")
parser$add_argument("--outf", type="character", help = "Output file")
parser$add_argument("--scriptDir", type="character", help = "Directory with R files necessary to SNF")
parser$add_argument("--clust", type="character", choices=c('spectral', 'fastgreedy') ,help = "Clustering method on fused graph")
parser$add_argument("--infoclust", action="store_true", help = "Number of groups from clustering method must be equal to number of classes? [default = TRUE]")

args <- parser$parse_args()

# Read input parameters
dataFile1 <- args$d1
dataFile2 <- args$d2
labFile <- args$lab
outFile <- args$outf
sDir <- args$scriptDir
clustMethod <- args$clust
clustInfo <- args$infoclust

print (clustInfo)
# load R scripts
file_names <- as.list(dir(path=sDir, pattern="*", full.names=TRUE))
lpack <- lapply(file_names,source,.GlobalEnv)

# load files
data16s <- read.table(dataFile1, sep='\t', header=TRUE, check.names=FALSE, row.names=1)
dataITS2 <- read.table(dataFile2, sep='\t', header=TRUE, check.names=FALSE, row.names=1)
lab <- read.table(labFile, as.is=TRUE, sep='\t')
lab <- lab[[1]]

# number of features
nbact <- ncol(data16s)
nfungi <- ncol(dataITS2)

# data normalization (mean 0, std 1)
data16s_n <- standardNormalization(data16s)
dataITS2_n <- standardNormalization(dataITS2)

# Calculate pairwise distance between samples
dist16s <- dist2(as.matrix(data16s_n), as.matrix(data16s_n))
distITS2 <- dist2(as.matrix(dataITS2_n), as.matrix(dataITS2_n))

# Parameters tuning (K, alpha)
opt_par <-  snf_tuning(dist16s, distITS2, lab=lab, clm=clustMethod, infocl=clustInfo)
K_opt <- opt_par[[1]]
alpha_opt <- opt_par[[2]]

# Similarity graphs
W16s = affinityMatrix(dist16s, K=K_opt, alpha_opt)
WITS2 = affinityMatrix(distITS2, K=K_opt, alpha_opt)

# Fuse the graphs
W = SNF(list(W16s,WITS2),K=K_opt)
# Rescale fused graph
W_sc <- W/max(W)
colnames(W_sc) <- rownames(data16s)
  
# Write fused graph
outfused <- gsub('.txt', '_similarity_mat_fused.txt', outFile)
write.table(cbind(Samples=colnames(W_sc), W_sc), file=outfused, quote=FALSE, sep='\t', row.names=FALSE, col.names=TRUE)

if (clustMethod=="spectral"){
  if (clustInfo){
    # Impose number of clusters (based on true samples labels)
    nclust <- length(unique(lab))
    group <-  spectralClustering(W, nclust)
  } else {
    nclust <- estimateNumberOfClustersGivenGraph(W)[[1]]
    # Spectral clustering
    group <-  spectralClustering(W, nclust)
  }
    
} else if (clustMethod=="fastgreedy"){
  # Rescale fused graph, so to apply community detection 
  W_sc <- W/max(W)
  # Graph from similarity matrix
  g <- graph.adjacency(W_sc, weighted = TRUE, diag=FALSE, mode='undirected')
  # Community detection
  m  <- cluster_fast_greedy(g)
  if (clustInfo){
    # Impose number of clusters (based on true samples labels)
    nclust <- length(unique(lab))
    group <- cutree(as.hclust(m), nclust)
  group} else {
    group <- m$membership
  }
}

# Goodness of clustering
# The closer SNFNMI to 0, the less similar the inferred clusters are to the real ones
SNFNMI_allfeats <-  calNMI(group, lab)

# Write out SMI score computed by using all features
outNMI <- gsub('.txt', '_NMI_score.txt', outFile)
write.table(SNFNMI_allfeats, file=outNMI, quote=FALSE, col.names=FALSE, row.names=FALSE)

#### For a posteriori features ranking, build affinity matrix on one feature at a time ####

# Test importance of each bacteria to subtypes finding
SNFNMI_bact <- rep(0,nbact)

for (f in c(1:nbact)){
  data16s_onefeat <- as.matrix(standardNormalization(data16s[,f]))
  
  # Calculate pairwise distance between samples
  dist16s <- dist2(as.matrix(data16s_onefeat), as.matrix(data16s_onefeat))
  
  # Similarity graphs
  W16s = affinityMatrix(dist16s, K=K_opt, alpha_opt) 
  
  
  if (clustMethod=="spectral"){
    if (clustInfo){
      # Impose number of clusters (based on true samples labels)
      nclust <- length(unique(lab))
      group_fi <-  spectralClustering(W16s, nclust)
    } else {
      nclust <- estimateNumberOfClustersGivenGraph(W16s)[[1]]
      # Spectral clustering
      group_fi <-  spectralClustering(W16s, nclust)
    }
      
  } else if (clustMethod=="fastgreedy"){
    # Rescale fused graph, so to apply community detection 
    W16s_sc <- W16s/max(W16s)
    # Graph from similarity matrix
    g <- graph.adjacency(W16s_sc, weighted = TRUE, diag=FALSE, mode='undirected')
    # Community detection
    m  <- cluster_fast_greedy(g)
    if (clustInfo){
      # Impose number of clusters (based on true samples labels)
      nclust <- length(unique(lab))
      group_fi <- cutree(as.hclust(m), nclust)
    } else {
      group_fi <- m$membership
    }
  }

  # Goodness of clustering
  # The closer SNFNMI to 0, the less similar the inferred clusters are to the real ones
  SNFNMI_bact[f] <- calNMI(group_fi, group)
}

# Test importance of each bacteria to subtypes finding
SNFNMI_fungi <- rep(0,nfungi)

for (f in c(1:nfungi)){
  
  dataITS2_onefeat <- as.matrix(standardNormalization(dataITS2[,f]))
  
  # Calculate pairwise distance between samples
  distITS2 <- dist2(as.matrix(dataITS2_onefeat), as.matrix(dataITS2_onefeat))
  
  # Similarity graphs
  WITS2 = affinityMatrix(distITS2, K=K_opt, alpha_opt)
  #WITS2 = affinityMatrix(distITS2)
  
  if (clustMethod=="spectral"){
    if (clustInfo){
      # Impose number of clusters (based on true samples labels)
      nclust <- length(unique(lab))
      group_fi <-  spectralClustering(WITS2, nclust)
    } else {
      nclust <- estimateNumberOfClustersGivenGraph(WITS2)[[1]]
      # Spectral clustering
      group_fi <-  spectralClustering(WITS2, nclust)
    }
    
  } else if (clustMethod=="fastgreedy"){
    # Rescale fused graph, so to apply community detection 
    WITS2_sc <- WITS2/max(WITS2)
    # Graph from similarity matrix
    g <- graph.adjacency(WITS2_sc, weighted = TRUE, diag=FALSE, mode='undirected')
    # Community detection
    m  <- cluster_fast_greedy(g)
    if (clustInfo){
      # Impose number of clusters (based on true samples labels)
      nclust <- length(unique(lab))
      group_fi <- cutree(as.hclust(m), nclust)
    } else {
      group_fi <- m$membership
    }
  }
  
  # Goodness of clustering
  # The closer SNFNMI to 0, the less similar the inferred clusters are to the real ones
  SNFNMI_fungi[f] <- calNMI(group_fi, group)
}
# Associate feature name to respective SNFNMI score
names(SNFNMI_bact) <- colnames(data16s)
names(SNFNMI_fungi) <- colnames(dataITS2)
# Combine bacteria and fungi results
SNFNMI_integr <- c(SNFNMI_bact, SNFNMI_fungi)

# Sort (decreasing) features based on SNFNMI score
idx_snfnmi <- order(SNFNMI_integr, decreasing=TRUE)
SNFNMI_integr_sort <- SNFNMI_integr[idx_snfnmi]

# Convert list to a matrix for output file format purposes
ranked_list <- as.matrix(SNFNMI_integr_sort)
colnames(ranked_list) <- c("SNFNMI_score")

# Number of communities found
ncommun <- length(unique(group))
ml <- vector('numeric')
for (i in c(1:ncommun)){
  ml[i] <- length(which(group==i))
}
# Largest community
max_comm <- max(ml)
# Matrix to save communities (one per row )
commun_mat <- matrix("NaN", nrow=ncommun, ncol=max_comm+1)

for (i in c(1:ncommun)){
  commun_mat[i,0:ml[i]+1] <- c(paste("Community_",i,sep=''), which(group==i)-1)
}

# Write table with communities
outcomm <- gsub('.txt', '_communities.txt', outFile)
write.table(commun_mat, file=outcomm, sep='\t', row.names=FALSE, col.names=FALSE, quote=FALSE)

# Save workspace
outF_rdata <- gsub('.txt', '.RData', outFile)
save.image(outF_rdata)

# Write output file
write.table(cbind(Features=rownames(ranked_list), ranked_list), file=outFile, quote=FALSE, sep='\t', row.names=FALSE, col.names=TRUE)

# Write median NMI score for all possible combinations of parameters K and alpha
out_med_NMI <- gsub('.txt', '_median_NMI_params.txt', outFile)
med_NMI_params <- opt_par[[3]]
write.table(cbind(Parameters=rownames(med_NMI_params), med_NMI_params), file=out_med_NMI, quote=FALSE, sep='\t', row.names=FALSE, col.names=TRUE)