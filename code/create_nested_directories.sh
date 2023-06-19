#!/bin/bash

base_directory="/scratch/a/arisvoin/clarasun/SCanD_project_PNC/data/local/bids"
parent_directory_prefix="sub-"

# Iterate through the sub--X directories
for sub_directory in ${base_directory}/${parent_directory_prefix}*
do
    # parent_directory="${base_directory}/${parent_directory_prefix}$"
    # base_directory="/scratch/a/arisvoin/clarasun/SCanD_project_PNC/data/local/bids"
    # parent_directory="/scratch/a/arisvoin/clarasun/SCanD_project_PNC/data/local/bids/sub-"
    nested_directory="${sub_directory}/dwi_temp"
    
    mkdir -p "${nested_directory}"
    # echo "Creating nested dwi_temp directories"
done
