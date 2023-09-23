#!/bin/bash

# Specify the root directory where you want to remove 'dwi_temp' folders
root_directory="/scratch/a/arisvoin/clarasun/SCanD_project_PNC/data/local/bids_copy"

# Use the 'find' command to locate all 'dwi_temp' folders and delete them
find "$root_directory" -type d -name "dwi_temp" -exec rm -r {} +

echo "All 'dwi_temp' folders have been removed."