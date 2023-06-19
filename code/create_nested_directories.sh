#!/bin/bash

base_directory="/scratch/a/arisvoin/clarasun/SCanD_project_PNC/data/local/bids"
parent_directory="/scratch/a/arisvoin/clarasun/SCanD_project_PNC/data/local/bids/sub-606855754171"

for parent_directory in base_directory
do
    # parent_directory="${base_directory}/${parent_directory_prefix}$"
    parent_directory="/scratch/a/arisvoin/clarasun/SCanD_project_PNC/data/local/bids/sub-606855754171"
    nested_directory="${parent_directory}/dwi_temp"
    
    mkdir -p "${nested_directory}"
done
