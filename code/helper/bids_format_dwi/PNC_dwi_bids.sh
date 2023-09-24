#!/bin/bash

##################################################################################
# This shell script converts raw DTI data from the PNC cohort into bids valid format
# Adapted from bids starter kit tutorial: https://reproducibility.stanford.edu/bids-tutorial-series-part-1b/#auto5
# Working with raw DTI data from a single session with two runs, DTI data has already been converted from DICOM to Nifti (.nii.gz)

set -e
####Defining pathways
toplvl=/scratch/a/arisvoin/desmith/PNC/data/dti # where raw DTI data is located
# dcmdir=/ ---> not necessary b/c dwi data has already been converted from DICOM to nii.gz
# dcm2niidir=/ ---> not necessary b/c dwi data has already been converted from DICOM to nii.gz
#Create nifti directory
mkdir ${toplvl}/Nifti
# niidir=${toplvl}/Nifti --> original niidir (where raw dti data is located)
niidir=${toplvl}/Nifti

#Changing directory into the subject folder
cd ${niidir}/sub-${subj}/dti


###### STEP 6 ######
#change dwi
#Example filename: 2475376_session2_DIFF_137_AP_RR
# Example PNC: 18991230_000000DTI2x3235s008a001.nii.gz

#BIDS filename: sub-2475376_ses-2_dwi
# Example PNC: sub-605153438249_run-1_dwi
#difffiles will capture how many filenames to change
difffiles=$(ls -1 *18991230* | wc -l) #Changed DIFF to 18991230
for ((i=1;i<=${difffiles};i++));
do
	Diff=$(ls *18991230*) #This is to refresh the diff variable, same as the cases above. 
	tempdiff=$(ls -1 $Diff | sed '1q;d')
	tempdiffext="${tempdiff##*.}"
	tempdifffile="${tempdiff%.*}"
	Runnum=$(echo $tempdifffile | cut -d '_' -f2) #Changed Sessionnum to Runnum
	Difflast=$(echo "${Runnum: -1}")
	if [ $Difflast >  ]; then # separate run 2 and run 1 --> HOW TO DO THIS?
	run=2
	else
	run=1
	fi
	mv ${tempdifffile}.${tempdiffext} sub-${subj}_run-${run}_dwi.${tempdiffext}
	echo "$tempdiff changed to sub-${subj}_run-${run}_dwi.${tempdiffext}"
done

###### TESTING ######
import os
root_path = '/scratch/a/arisvoin/desmith/PNC/data/bids'
folder= 'dwi_temp'
for '/scratch/a/arisvoin/desmith/PNC/data/bids/sub-*' in '/scratch/a/arisvoin/desmith/PNC/data/bids':
    os.mkdir(os.path.join)

import os
os.makedirs("/scratch/a/arisvoin/desmith/PNC/data/bids/sub-*/dwi_temp")

########################################################################
# NEW TESTING #
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
				print("hello from run 1")
                new_filename = f"sub-{destination_pattern}_run-1_dwi{os.path.splitext(filename)[1]}"
            elif "DTI2x3236" in filename:
				print("hello from run 2")
                new_filename = f"sub-{destination_pattern}_run-2_dwi{os.path.splitext(filename)[1]}"
            else:
                # Skip files that don't match the criteria
                continue

            # Construct the full path of the destination file
            destination_path = os.path.join("/scratch/a/arisvoin/clarasun/SCanD_project_PNC/data/local/bids", destination_pattern, "dwi_temp", new_filename)

            # Create the destination directory if it doesn't exist
            os.makedirs(os.path.dirname(destination_path), exist_ok=True)

            # Copy the file to the destination directory
            shutil.copy2(source_path, destination_path)

# Usage example:
source_directory = "/scratch/a/arisvoin/desmith/PNC/data/dti"
destination_pattern = "606860220952-test"

rename_and_copy_files(source_directory, destination_pattern)

