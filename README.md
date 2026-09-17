# common_bean_SNPs_Indels_prediction
Common bean - common bacterial blight prediction using SNPs and InDel annotations in machine learning models


Code and scripts used to generate results for "" Mohamedikbal et al.

**Phenotype data:**
- Phenotype data for common bacterial blight retrieved from https://doi.org/10.3389/fpls.2024.1469381

**Genotype data:**
- WGS sequencing reads for Andean diversity panel obtained from NCBI-SRA https://doi.org/10.1002/tpg2.20523 


## Analysis Pipeline

### **1: SNP-calling**
- SNP calling and filtering using GATK
- **Scripts**:```01_GATK.sh```

### **2: ML using LD-pruned SNPs as features**
- Identify best performing ML model for this dataset
- SNP prioritisation and candidate gene identification using stability selection and repeated K-fold
- **Scripts**:```02_ML_with_SNPs.py```
