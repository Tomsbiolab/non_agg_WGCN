#!/bin/bash

#SBATCH --job-name=_GIT_non_agg_root
#SBATCH --output=res_root_TOP420_non_agg%j.txt
#SBATCH --partition=long
#SBATCH --time=5-23:00:00
#SBATCH --ntasks=1 
#SBATCH --cpus-per-task=30
#SBATCH --mem=500gb

module load python/3.8
module load R/4.2.1

# Choose from the following tissues (leaf, fruit, seedless_fruit, root, stem, wood, flower, seed, tendril, bud, mix) and list them separated by a semicolon (e.j. leaf;berry will do the network of both leaf and berry tissues). For doing the independent network, tissue='ALL'.
# Remember to change job-name and output with the tissue

#PARAMETERS TO EDIT

metadata_file='/storage/TOM/SRA_vitis/metadata/final_classification.csv'
count_summaries_folder='/storage/TOM/SRA_vitis/count_summaries/'
count_matrices_folder='/storage/TOM/SRA_vitis/count_matrices/'
tissue='root'
result_folder='/storage/TOM/SRA_vitis/network/non_agg_root'
scripts='/storage/TOM/SRA_vitis/scripts/GITHUB_non_agg_network_pipeline'
anno='/storage/TOM/SRA_vitis/scripts/GITHUB_non_agg_network_pipeline/annotations.rda'

# DO NOT TOUCH ANYTHING BELOW THIS LINE

cd $scripts

echo 
echo '**************** PREPARING RAW COUNTS MATRIX ****************'
echo 

# The "preparing_experiments_folders.py" script selects all the runs in SRA that come from the selected tissue/s, copy then in the base folder, removes the runs with less than 10 M alignments, separate the runs in their respective experiment folders and finally removes the experiments with less than 4 runs.

base=$result_folder
all_counts=$base'/all_counts_folder'
raw_counts=$base'/raw_counts/raw_counts.csv'
FPKM_counts=$base'/FPKM_counts/FPKM_all_counts.txt'
PCC=$base'/PCC_matrix/PCC.txt'
HRR=$base'/HRR_matrix/HRR_no_filtered.csv'

mkdir -p $base

python3 preparing_experiments_folders.py --tissues_list $tissue --network_folder $base --metadata_file $metadata_file --count_summaries_folder $count_summaries_folder --count_matrices_folder $count_matrices_folder

# The "loop_merge_matrix.py" script iterates the experiment folders and generates a raw count matrix for experiment. This new raw count matrix (referred from now on as "all_counts" matrix) contains the counts of every run of the experiment.

python3 loop_merge_matrix.py -r $base -s $scripts

# Putting all the all counts files from all the experiments together.

python3 uniting_all_counts.py -p $base

# Merging the experiments counts in a huge raw counts matrix.

mkdir $base'/raw_counts'
python3 merge_experiments.py -i $all_counts -o $raw_counts

echo 
echo '**************** COMPUTING PCC MATRIX FOR EVERY EXPERIMENT ****************'
echo 

# The "generating_PCC.R" Rscript computes the PCC matrix for the raw count matrix that contains all the runs of the network. Briefly, this Rscript does a FPKM normalization of the raw counts and filters out the genes that in all the samples FPKM < 0.5. After that, with the remaining genes, it computes the PCC for the experiment. The Rscript also saves the non-filtered FPKM matrix (input for the heatmaps of expression across the network runs).

mkdir $base'/FPKM_counts'
mkdir $base'/PCC_matrix'

Rscript generating_PCC.R $FPKM_counts $raw_counts $PCC $anno $scripts

echo 
echo '**************** COMPUTING HRR MATRIX FOR EVERY EXPERIMENT ****************'
echo 

# Generating the HRR matrix for the non_agg network with the "computing_HRR_matrix_TOP420.py" script. This script will analyze the PCC matrix in order to generate its corresponding HRR matrix.

mkdir $base'/HRR_matrix'
python3 -u computing_HRR_matrix_TOP420.py -p $PCC -o $HRR -t 30

echo
echo '**************** FORMATING, FILTERING AND EVALUATING THE CO-OCCURRENCE MATRIX ****************'
echo

# The "top1_co_occurrence_matrix_version2_TOP420.py" script will filter the HRR matrix, keeping only the TOP 420 co-expressed genes for each row of the non-filtered co-occurrence matrix. This script will output the filtered HRR matrix in both EGAD and Cytoscape format.

python3 -u top1_co_occurrence_matrix_version2_TOP420_removing_ties.py -p $HRR -c $base'/HRR_matrix/non_agg_filtered_net_Cyto.csv' -e $base'/HRR_matrix/non_agg_filtered_net_EGAD.csv'

python3 -u top1_co_occurrence_matrix_version2_TOP420_keeping_ties.py -p $HRR -c $base'/HRR_matrix/non_agg_full_net_Cyto.csv' -e $base'/HRR_matrix/non_agg_full_net_EGAD.csv'

# The "EGAD_final_aggregation.R" will evaluate the final co-occurrence matrix, providing a AUROC value for the given ontology.

Rscript EGAD_final_aggregation.R $scripts/mapman_corrected_stilbenoid_anthocyanins.csv $base'/HRR_matrix/non_agg_filtered_net_EGAD.csv' $base'/HRR_matrix/non_agg_filtered_egad_out.txt' all_experiments

Rscript EGAD_final_aggregation.R $scripts/mapman_corrected_stilbenoid_anthocyanins.csv $base'/HRR_matrix/non_agg_full_net_EGAD.csv' $base'/HRR_matrix/non_agg_full_egad_out.txt' all_experiments
