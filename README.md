# ml_rSNFi: Integrative Network Fusion of meta-omics data for the identification of robust biomarkers
ml-rSNFi is a bioinformatics framework for the identification of integrated meta-omics biomarkers. The framework is based on the predictive profiling of meta-omics data abundances with a novel approach to their integration. First, we perform a gold
standard omics concatenation with a Random Forest (RF) model. Secondly, we introduce rSNF, a feature ranking scheme on integrative features that extends Similarity Network Fusion (SNF) [Wang et al, Nat Methods, 2014], a non-Bayesian network-based method. The rSNF-ranking is then used with a RF classifier instead of mean decrease in the Gini impurity over the multi-omics features. A compact model (ml-rSNFi) trained on the intersection of features from direct concatenation and rSNF features is then derived.

In this repository we test the framework on an high-quality human IBD clinical dataset from the Gastroenterology Department of the Saint Antoine Hospital (Paris, F), integrating bacterial and fungal fecal microbiota from IBD patients (6 phenotypes) and healthy subjects.

The repository includes:

- OTU_tables: OTU tables for training (<*_16S_ITS2_tr.txt>) and validatation (<*_16S_ITS2_ts.txt>) of predictive models. One table for classification task.

- Labels: samples associated to corresponding phenoptypes, both for training (<*_tr.lab>) and for validation (<*_ts.lab>) datasets. Files <*_tr_bin.lab> and <*_ts_bin.lab>, phenotypes are binarized, samples are in the same order as in <*_tr.lab> and <*_ts.lab>, respectively.

- scripts: scripts included in ml-rSNFi framework
