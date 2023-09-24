# SCanD_project

This is a base repo for the Schizophrenia Canadian Neuroimaging Database (SCanD) codebase. It is meant to be folked/cloned for every SCanD dataset

General folder structure for the repo (when all is run)

```
${BASEDIR}
├── code                         # a clone of this repo
│   └── ...    
├── containers                   # the singularity image are copied or linked to here
│   ├── fmriprep-20.1.1.simg 
│   ├── fmriprep_ciftity-v1.3.2-2.3.3.simg 
│   └── mriqc-22.0.6.simg simg
├── data
│   ├── local                    # folder for the "local" dataset
│   │   ├── bids                 # the defaced BIDS dataset
│   │   ├── mriqc                # mriqc derivatives
│   │   ├── fmriprep             # fmriprep derivatives
│   │   ├── freesurfer           # freesurfer derivative - generated during fmriprep
│   │   ├── ciftify              # ciftify derivatives
│   │   ├── cifti_clean          # dtseries post confound regression
│   │   └── parcellated          # parcellated timeseries
│   |
│   └── share                    # folder with a smaller subset ready to share
│       ├── ciftify              # contains only copied over qc images and logs
│       ├── fmriprep             # contains only qc images, metadata and anat tsvs
│       └── parcellated          # contains the parcellated data
├── logs                       # logs from jobs run on cluster                 
|── README.md
└── templates                  # an extra folder with pre-downloaded fmriprep templates (see setup section)
    └── parcellations
        ├── README.md
        └── tpl-fsLR_res-91k_atlas-GlasserTianS2_dseg.dlabel.nii
```

Currently this repo is going to be set up for running things on SciNet Niagara cluster - but we can adapt later to create local set-ups behind hospital firewalls if needed.

# The general overview of what to do

1. Organize your data into BIDS..
2. Deface the BIDS data (if not done during step 1)
3. Setting your SciNet enviroment/code/and data
   1. Clone the Repo
   2. Run the software set-up script (takes a few seconds)
   3. Copy or link your bids data to this folder
4. Run MRIQC
5. Run fmriprep
6. Run ciftify
7.  Run ciftify_clean and parcellate
8.  Run the scripts to extract sharable data into the sharable folder
9.  A script for NODDI is included in the code but this will not run on the PNC dataset because it was collected using a single shell.

## Organize your data into BIDS

This is the longest - most human intensive - step. But it will make everything else possible! BIDS is really a naming convention for your MRI data that will make it easier for other people the consortium (as well as the software) to understand what your data is (what scan types, how many participants, how many sessions..ect). Converting to BIDS may require renaming and/or reorganizing your current data. No coding is required, but there now a lot of different software projects out there to help out with the process.

For amazing tools and tutorials for learning how to BIDS convert your data, check out the [BIDS starter kit](https://bids-standard.github.io/bids-starter-kit/).

## Deface the BIDS data (if not done during step 1)

A useful tool is [this BIDSonym BIDS app](https://peerherholz.github.io/BIDSonym/).

## Setting your SciNet enviroment/code/and data

### Cloning this Repo

```sh
cd $SCRATCH
git clone https://github.com/TIGRLab/SCanD_project.git
```

### Run the software set-up script

```sh
cd ${SCRATCH}/SCanD_project
source code/00_setup_data_directories.sh
```

### put your bids data into the data/local folder

We want to put your data into:

```
./data/local/bids
```

You can do this by either copying "scp -r", linking `ln -s` or moving the data to this place - it's your choice.

To copy the data from another computer/server you should be on the datamover node:


```sh
ssh <cc_username>@niagara.scinet.utoronto.ca
ssh nia-dm1
rsync -av <local_server>@<local_server_address>:/<local>/<server>/<path>/<bids> ${SCRATCH}/SCanD_project/data/local/
```

To link existing data from another location on SciNet Niagara to this folder:

```sh
ln -s /your/data/on/scinet/bids ${SCRATCH}/SCanD_project/data/local/bids
```


## Running mriqc

```sh
## note step one is to make sure you are on one of the login nodes
ssh niagara.scinet.utoronto.ca

## go to the repo and pull new changes
cd ${SCRATCH}/SCanD_project
git pull         #in case you need to pull new code

## calculate the length of the array-job given
SUB_SIZE=10
N_SUBJECTS=$(( $( wc -l ./data/local/bids/participants.tsv | cut -f1 -d' ' ) - 1 ))
array_job_length=$(echo "$N_SUBJECTS/${SUB_SIZE}" | bc)
echo "number of array is: ${array_job_length}"

## submit the array job to the queue
sbatch --array=0-${array_job_length} ./code/01_mriqc.sh
```

## Running fmriprep-anatomical (includes freesurfer)

Note: this step uses and estimated **16hrs for processing time** per participant! So if all participants run at once (in our parallel cluster) it will still take a day to run.

```sh
## note step one is to make sure you are on one of the login nodes
ssh niagara.scinet.utoronto.ca

# module load singularity/3.8.0 - singularity already on most nodes
## go to the repo and pull new changes
cd ${SCRATCH}/SCanD_project
git pull         #in case you need to pull new code

## calculate the length of the array-job given
SUB_SIZE=5
N_SUBJECTS=$(( $( wc -l ./data/local/bids/participants.tsv | cut -f1 -d' ' ) - 1 ))
array_job_length=$(echo "$N_SUBJECTS/${SUB_SIZE}" | bc)
echo "number of array is: ${array_job_length}"

## submit the array job to the queue
sbatch --array=0-${array_job_length} code/01_fmriprep_anat_scinet.sh
```

## submitting the fmriprep func step 

Running the functional step looks pretty similar to running the anat step. The time taken and resources needed will depend on how many functional tasks exists in the experiment - fMRIprep will try to run these in paralell if resources are available to do that.

Note -  the script enclosed uses some interesting extra opions:
 - it defaults to running all the fmri tasks - the `--task-id` flag can be used to filter from there
 - it is running `synthetic distortion` correction by default - instead of trying to work with the datasets available feildmaps - because feildmaps correction can go wrong - but this does require that the phase encoding direction is specificed in the json files (for example `"PhaseEncodingDirection": "j-"`).

```sh
## note step one is to make sure you are on one of the login nodes
ssh niagara.scinet.utoronto.ca

## go to the repo and pull new changes
cd ${SCRATCH}/SCanD_project
git pull

## figuring out appropriate array-job size
SUB_SIZE=2 # for func the sub size is moving to 1 participant because there are two runs and 8 tasks per run..
N_SUBJECTS=$(( $( wc -l ./data/local/bids/participants.tsv | cut -f1 -d' ' ) - 1 ))
array_job_length=$(echo "$N_SUBJECTS/${SUB_SIZE}" | bc)
echo "number of array is: ${array_job_length}"

## submit the array job to the queue
sbatch --array=0-${array_job_length} ./code/02_fmriprep_func_scinet.sh
```

### running ciftify

```sh
## note step one is to make sure you are on one of the login nodes
ssh niagara.scinet.utoronto.ca

## go to the repo and pull new changes
cd ${SCRATCH}/SCanD_project
git pull

## figuring out appropriate array-job size
SUB_SIZE=8 # for func the sub size is moving to 1 participant because there are two runs and 8 tasks per run..
N_SUBJECTS=$(( $( wc -l ./data/local/bids/participants.tsv | cut -f1 -d' ' ) - 1 ))
array_job_length=$(echo "$N_SUBJECTS/${SUB_SIZE}" | bc)
echo "number of array is: ${array_job_length}"

## submit the array job to the queue
cd ${SCRATCH}/SCanD_project
sbatch --array=0-${array_job_length} ./code/03_ciftify_scinet.sh
```

### running qsiprep

```sh
## note step one is to make sure you are on one of the login nodes
ssh niagara.scinet.utoronto.ca

## go to the repo and pull new changes
cd ${SCRATCH}/SCanD_project
git pull

## figuring out appropriate array-job size
SUB_SIZE=2 # for func the sub size is moving to 1 participant because there are two runs and 8 tasks per run..
N_SUBJECTS=$(( $( wc -l ./data/local/bids/participants.tsv | cut -f1 -d' ' ) - 1 ))
array_job_length=$(echo "$N_SUBJECTS/${SUB_SIZE}" | bc)
echo "number of array is: ${array_job_length}"

## submit the array job to the queue
cd ${SCRATCH}/SCanD_project
sbatch --array=0-${array_job_length} ./code/02_qsiprep_scinet.sh
```

## running cifti clean

```sh
## note step one is to make sure you are on one of the login nodes
ssh niagara.scinet.utoronto.ca

## go to the repo and pull new changes
cd ${SCRATCH}/SCanD_project
git pull

## figuring out appropriate array-job size
SUB_SIZE=10 # for func the sub size is moving to 1 participant because there are two runs and 8 tasks per run..
N_DTSERIES=$(ls -1d ./data/local/ciftify/sub*/MNINonLinear/Results/*task*/*dtseries.nii | wc -l)
array_job_length=$(echo "$N_DTSERIES/${SUB_SIZE}" | bc)
echo "number of array is: ${array_job_length}"

## submit the array job to the queue
sbatch --array=0-${array_job_length} ./code/04_cifti_clean.sh
```

## running the parcellation step

```sh
## note step one is to make sure you are on one of the login nodes
ssh niagara.scinet.utoronto.ca

## go to the repo and pull new changes
cd ${SCRATCH}/SCanD_project
git pull

## figuring out appropriate array-job size
SUB_SIZE=10 # for func the sub size is moving to 1 participant because there are two runs and 8 tasks per run..
N_DTSERIES=$(ls -1d ./data/local/ciftify/sub*/MNINonLinear/Results/*task*/*dtseries.nii | wc -l)
array_job_length=$(echo "$N_DTSERIES/${SUB_SIZE}" | bc)
echo "number of array is: ${array_job_length}"

## submit the array job to the queue
sbatch --array=0-${array_job_length} ./code/05_parcellate.sh
```

## syncing the data with to the share directory

This step does calls some "group" level bids apps to build summary sheets and html index pages. It also moves a meta data, qc pages and a smaller subset of summary results into the data/share folder.

It takes about 10 minutes to run (depending on how much data you are synching). It could also be submitted.

```sh
## note step one is to make sure you are on one of the login nodes
ssh niagara.scinet.utoronto.ca

## go to the repo and pull new changes
cd ${SCRATCH}/SCanD_project
git pull

source ./code/06_extract_to_share.sh
```

# Appendix - Adding a test dataset from openneuro

#### (To test this repo - using an openneuro dataset)

To get an openneuro dataset for testing - we will use datalad

##### loading datalad on SciNet niagara

```sh
## loading Erin's datalad environment on the SciNet system
module load git-annex/8.20200618 # git annex is needed by datalad
module use /project/a/arisvoin/edickie/modules #this let's you read modules from Erin's folder
module load datalad/0.15.5 # this is the datalad module in Erin's folder
```

##### using datalad to install a download a dataset

```
cd ${SCRATCH}/SCanD_project/data/local/
datalad clone https://github.com/OpenNeuroDatasets/ds000115.git bids
```

Before running fmriprep anat get need to download/"get" the anat derivatives

```
cd bids
datalad get sub*/anat/*T1w.nii.gz
```
Before running fmriprep func - we need to download the fmri scans

```
cd bids
datalad get sub*/func/*
```

But - with this dataset - there is also the issue that this dataset is old enough that no Phase Encoding Direction was given for the fMRI scans - we really want at least to have this so we can run Synth Distortion Correction. So we are going to guess it..

To guess - we add this line into the middle of the top level json ().

```
"PhaseEncodingDirection": "j-",
```

note: now - thanks to the people at repronim - we can also add the repronim derivatives !

```{r}
cd ${SCRATCH}/SCanD_project/data/local/ls

datalad clone https://github.com/OpenNeuroDerivatives/ds000115-fmriprep.git fmriprep
datalad clone https://github.com/OpenNeuroDerivatives/ds000115-mriqc.git mriqc
```

getting the data files we actually use for downstream ciftify things

# Helper Scripts
The “helper” subdirectory within the code directory contains scripts that were created to assist with various preprocessing steps. Specifically, several scripts were used to bids format diffusion weighted imaging (DWI) data, others scripts track the completion of pipeline steps, and several assist with performing quality control on fMRIprep derivatives. These categories of scripts are described in more detail below. Before running these scripts, double check all paths (i.e., base/source directory and destination paths where applicable). Many of these paths are currently hardcoded to a specific directory. Any destination paths should be changed to the user’s desired path.

## Where should the scripts be run and in what order?
- Jupyter notebooks (.ipynb) were created with the intention of running on SciNet
- Bash shell scripts (.sh) can be run in a terminal on SciNet or local terminal, depending on where input/output files are located
- Python scripts (.py) were created to run on the user’s local terminal (assuming inputs were saved to local terminal) but can be modified to run on SciNet
- Some of the scripts start with a number to indicate the relative order they should be run in; others have no numbers and can be run independently (stand alone) 

### Note: all helper scripts were added to the `fmriprep_lts` branch of `/ScanD_project_PNC` GitHub repository

## Scripts for bids formatting DWI 

#### Located in `/SCanD_project_PNC/code/helper/bids_format_dwi/`

#### `01_create_nested_directories.sh`
Creates a nested `dwi_temp` folder within each participant’s bids folder.

#### `02_rename_and_copy.py`
Run this script after nested “dwi” folders have been created (i.e., after running `create_nested_directories.sh`). This script renames raw diffusion tensor imaging (DTI) data and metadata into the required bids format, then copies this data into each participant’s nested DWI folder in their bids folder. 

#### `03_remove_nested_directories.sh`
Removes the `dwi_temp` folder created by `create_nested_directories.sh`. Script can be customized by replacing `dwi_temp` with a desired nested folder name, to iterate through and delete all instances of this folder.

#### `PNC_dwi_bids.sh`
This is an older version of the `rename_and_copy.py` script created for testing purposes. Not intended to be run but can be a reference for code snippets from the bids starter kit tutorial. 

## Scripts for tracking pipeline completion

#### Located in `/SCanD_project_PNC/code/helper/track_pipeline_completion/`

#### count_missing_files.ipynb
Script that tracks the completion of pipeline steps by comparing a count of output files that exist to the expected number. Uses `os` module to check if paths exist. Includes sections for checking fMRIprep `anat` and `func` derivatives, ciftify and ciftify `qc_fmri` derivatives, bids `func` data, `cifti_clean` derivatives, `parcellate` derivatives, and missing `qsiprep` outputs. Run within /local/bids folder, create a copy of this notebook to your bids folder if needed.
 
#### remove_and_copy_fmriprep.ipynb
Script is used to delete subject folders that are in both `/fmriprep` and `/fmriprep/fmriprep`, 
where the version of the subject folder in `/fmriprep` has incomplete `anat` and/or `func` derivative folders. The reason `/fmriprep` and `/fmriprep/fmriprep/` folders were created is due to the pipeline being run with an older version of fMRIprep (outputs saved to `/fmriprep`) and and a newer version of fMRIprep (outputs saved to `/fmriprep/fmriprep`). 

#### delete_from_list.ipynb
Script to delete folders based on a list extracted from a TSV. Replace the `base_directory` and `tsv_file` with your desired paths.  

## Scripts for generating quality control viewing pages

#### Located in `/SCanD_project_PNC/code/helper/view_and_create_QC_pages/`

#### `00_QC_fmriprep_view.ipynb`
Adapted from code shared by Erin, this script displays functional and anatomical fMRIprep SVGs to perform quality control directly within Jupyter Notebook. Major limitation is that SVGs displayed are fixed, not animated. Useful for a quick scan of some anatomical derivatives. However, not ideal for functional SVGs because only a snapshot of the SVG is shown (e.g., only the “before” panel of susceptibility distortion correction images). Images also load quite slowly so the alternative approach using the `extract_svgs` scripts below is recommended.   

#### `01_extract_svgs.sh`
Creates a directory to store the extracted SVGs from fMRIprep folder. Script needs to be run within the user’s folder containing the results of running `06_extract_to_share.sh` (or alternatively, this script can be copied into the `share` folder). Modify the string suffix to extract different types of `anat` and `func` fMRIprep derivatives such as SDC, EPI to T1, etc.

#### `02_create_html_from_svgs.py`
To be run **after** creating a directory with extracted SVGs (i.e., run `extract_svgs.sh` first). Generates an HTML page with a specified number of SVGs grouped together per HTML file for QC’ing. Splits SVGs into groups instead of creating a single HTML page so each page can load faster. Sorts SVGs by participant ID so the pages can be viewed in alpha-numerical order. HTML page displays the SVG path and participant ID above each image. Note this file was previously named `extract_sdc_svgs_split.py`.

#### `no_split_html_from_svgs.py`
An alternate version of `create_html_from_svgs.py` that does **NOT** split SVGs into groups. Instead, a single HTML file with all SVGs is created. This script is not recommended unless you are working with a small number of SVGs (<100). Note this file was previously named `extract_sdc_svgs.py`.

