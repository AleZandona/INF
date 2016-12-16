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
# Requires R >= 3.2.3
snf_cv <- function(W, lab, K=5, N=10, clm, infocl){
  median_NMI <- list()
  nSamp <- dim(W)[1]
  SNFNMI_all <- list()
  set.seed(N)
  cv_folds <- generateCVRuns(lab, ntimes = N, nfold = K, stratified = TRUE)
  for (nfold in 1:N){
    #cv_folds <- cvFolds(nSamp, K=5, type="random")
    cv_folds_current <- cv_folds[[nfold]]
    SNFNMI_K <- list()
    for(l in 1:K){
      # subset of X by indexes selected with k-fold CV
      idx_k <- cv_folds_current[[l]]
      W_k <- W[idx_k,idx_k]
      # extract the respective labels
      lab_k <- lab[idx_k]
      if (clm=="spectral"){
        if (infocl){
          nclust <- length(unique(lab))
          # predict clusters for subset k of X
          group_k <- spectralClustering(W_k, nclust)
        }else{
          nclust <- estimateNumberOfClustersGivenGraph(W_k)[[1]]
          group_k <- spectralClustering(W_k, nclust)
        }
      } else if (clm=="fastgreedy") {
        W_sc_k <- W_k/max(W_k)
        g_k <- graph.adjacency(W_sc_k, weighted = TRUE, diag=FALSE, mode='undirected')
        m_k  <- cluster_fast_greedy(g_k)
        if (infocl){
          nclust <- length(unique(lab))
          group_k <- cutree(as.hclust(m_k), nclust)
        } else {
          group_k <- m_k$membership  
        }
      }
      # NMI score
      SNFNMI_K[l] <-  calNMI(group_k, lab_k)
    }
    
    # median of NMI score for current CV repetition
    median_NMI[nfold] <- median(unlist(SNFNMI_K))
  }
  # median of NMI score over all CV repetitions
  median_NMI_allrep <- median(unlist(median_NMI))
  return(med_NMI=median_NMI_allrep)
}

snf_tuning <- function(dist1, dist2, lab, clm, infocl){
  # Pairwise distance between samples of two different datasets
  dist_tab1 <- dist1
  dist_tab2 <- dist2

  # min and max K values
  minK <- 10
  maxK <- 30
  stepK <- 1
  K_values <- seq(minK,maxK,stepK)
  
  # min and max alpha values
  min_alpha <- 0.3
  max_alpha <- 0.8
  step_alpha <- 0.05
  alpha_values <- seq(min_alpha,max_alpha,step_alpha)
  
  registerDoParallel(cores=2)
  # for each combination of K and alpha, compute NMI score median over 10x5-CV
  NMI_tun <- foreach(K=K_values) %dopar% {foreach(alpha=alpha_values) %dopar% 
  {       W1_tun <-  affinityMatrix(dist_tab1, K=K, alpha);
          W2_tun <-  affinityMatrix(dist_tab2, K=K, alpha); 
          W_K <- SNF(list(W1_tun, W2_tun), K=K); 
          med_NMI <- snf_cv(W_K, lab, clm=clm, infocl=infocl)}
  }
  
  # K values
  nK <- length(seq(minK,maxK,stepK))
  # alpha values
  nalpha <- length(seq(min_alpha,max_alpha,step_alpha))
  
  idx_max_alpha_fk <- list()
  max_nmi_fk <- list()
  tab_median_NMI <- matrix(,nrow=nK, ncol=nalpha)
  # Set rownames
  knames <- vector("character")
  ik <- 1
  for (i in seq(10,30,1)){
    knames[ik] <- paste('K',i,sep='_')
    ik <- ik+1
  }
  rownames(tab_median_NMI) <- knames
  
  # Set colnames
  anames <- vector("character")
  ia <- 1
  for (i in seq(0.3,0.8,0.05)){
    anames[ia] <- paste('alpha',i,sep='_')
    ia <- ia+1
  }
  colnames(tab_median_NMI) <- anames
  
  for (elk in c(1:nK)){
    
    # K fixed, find max NMI over all alpha values
    max_nmi_fk[elk] <- max(unlist(NMI_tun[[elk]]))
    tab_median_NMI[elk,] <- unlist(NMI_tun[[elk]])
    }
  # Find K corresponding to max NMI
  best_K_idx <- which.max(unlist(max_nmi_fk))[1]
  best_K <- K_values[best_K_idx]
  # Find alpha corresponding to max NMI (and previously found K)
  best_alpha_idx <- which.max(NMI_tun[[best_K_idx]])
  best_alpha <- alpha_values[best_alpha_idx]
  return(list(best_K=best_K, best_alpha=best_alpha, tab_median_NMI=tab_median_NMI))
}
