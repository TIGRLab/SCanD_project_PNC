#!/usr/bin/env python3

print('Hello World!')

import os
import shutil

def rename_and_copy_files(source_dir, destination_pattern):
    # Iterate over all files in the source directory and its subdirectories
    for root, dirs, files in os.walk(source_dir):
        for filename in files:
            # Construct the full path of the source file
            source_path = os.path.join(root, filename)

            # Check if the file matches the specified criteria
            if "DTI2x3235" in filename:
                new_filename = f"sub-{destination_pattern}_run-1_dwi{os.path.splitext(filename)[1]}"
            elif "DTI2x3236" in filename:
                new_filename = f"sub-{destination_pattern}_run-2_dwi{os.path.splitext(filename)[1]}"

            # Construct the full path of the destination file
            destination_path = os.path.join(
                 "/scratch/a/arisvoin/clarasun/SCanD_project_PNC/data/local/bids", 
                 destination_pattern, "dwi_temp", new_filename)

            # Create the destination directory if it doesn't exist
            os.makedirs(os.path.dirname(destination_path), exist_ok=True)

            # Copy the file to the destination directory
            shutil.copy2(source_path, destination_path)

# Usage example:
source_directory = "/scratch/a/arisvoin/desmith/PNC/data/dti"
destination_pattern = "606860220952-test"

rename_and_copy_files(source_directory, destination_pattern)