#!/bin/bash
#SBATCH --job-name=dtifit
#SBATCH --output=logs/%x_%j.out 
#SBATCH --nodes=1
#SBATCH --cpus-per-task=40
#SBATCH --time=2:00:00


SUB_SIZE=1 ## number of subjects to run is 1 because there are multiple tasks/run that will run in parallel 
CORES=40
export THREADS_PER_COMMAND=2

####----### the next bit only works IF this script is submitted from the $BASEDIR/$OPENNEURO_DS folder...

## set the second environment variable to get the base directory
BASEDIR=${SLURM_SUBMIT_DIR}

## set up a trap that will clear the ramdisk if it is not cleared
function cleanup_ramdisk {
    echo -n "Cleaning up ramdisk directory /$SLURM_TMPDIR/ on "
    date
    rm -rf /$SLURM_TMPDIR
    echo -n "done at "
    date
}

#trap the termination signal, and call the function 'trap_term' when
# that happens, so results may be saved.
trap "cleanup_ramdisk" TERM

# input is BIDS_DIR this is where the data downloaded from openneuro went
export BIDS_DIR=${BASEDIR}/data/local/bids_copy
# export BIDS_DIR=${BASEDIR}/data/local/bids

## these folders envs need to be set up for this script to run properly 
## see notebooks/00_setting_up_envs.md for the set up instructions
export QSIPREP_HOME=${BASEDIR}/templates
export SING_CONTAINER=${BASEDIR}/containers/qsiprep_0.16.0RC3.simg

## get the subject list from a combo of the array id, the participants.tsv and the chunk size
bigger_bit=`echo "($SLURM_ARRAY_TASK_ID + 1) * ${SUB_SIZE}" | bc`
SUBJECTS=`sed -n -E "s/sub-(\S*)\>.*/\1/gp" ${BIDS_DIR}/participants.tsv | head -n ${bigger_bit} | tail -n ${SUB_SIZE}`

## set singularity environment variables that will point to the freesurfer license and the templateflow bits
# Make sure FS_LICENSE is defined in the container.
export SINGULARITYENV_FS_LICENSE=/home/qsiprep/.freesurfer.txt

# set this to the local locaton of the SCanD_project_PNC repo
CODE_DIR=${PWD}

## set this to the QSIPREP outputs location
QSIPREP_DIR=${CODE_DIR}/data/local/qsiprep

## any tempdir and workdir location will do
TMP_DIR=${CODE_DIR}/data/local/temp_PNC
WORK_DIR=${TMP_DIR}/qsiprep_work

# set this to the location of a freesurfer license
FS_LICENSE=${TMP_DIR}/freesurfer_license/license.txt

# set this to the location to write the outputs to
OUT_DIR=${CODE_DIR}/data/local/

SUB_DWIS=`ls -1d ${QSIPREP_DIR}/sub-${SUBJECTS}/dwi/*desc-preproc_dwi.nii.gz`
for sub_dwi in $SUB_DWIS; do
  echo $sub_dwi
  base=$(basename ${sub_dwi})
  subject=$(cut -d'_' -f1 <<< $base)
  # subject_id=$(echo $subject | sed 's/sub-//g') # skip this because qsiprep dwi files start with sub- prefix
  run="$(cut -d'_' -f2 <<< $base)"
  ##### STEP 1 - if not done - qsiprep fslstd step ###################

singularity run \
  -H ${TMP_DIR} \
  -B ${BIDS_DIR}:/bids \
  -B ${QSIPREP_DIR}:/qsiprep_in \
  -B ${OUT_DIR}:/out \
  -B ${WORK_DIR}:/work \
  -B ${FS_LICENSE}:/li \
  ${SING_CONTAINER} \
  /bids /out participant \
  --skip-bids-validation \
  --participant_label ${subject_id} \
  --n_cpus 4 --omp-nthreads 2 \
  --recon-only \
  --recon-spec reorient_fslstd \
  --recon-input /qsiprep_in \
  --output-resolution 2.0 \
  --fs-license-file /li \
  -w /work \
  --notrack

######### STEP 2 - running DTIFIT - with BIDS names ##########################

QSIRECON_OUT=/out/qsirecon/sub-${subject_id}/dwi/sub-${subject_id}_${run}_space-T1w_desc-preproc_fslstd
DTIFIT_OUT=dtifit/sub-${subject_id}/dwi/sub-${subject_id}_${run}_space-T1w_desc-dtifit

mkdir -p $(dirname /${OUT_DIR}/${DTIFIT_OUT})

singularity exec \
  -H ${TMP_DIR} \
  -B ${BIDS_DIR}:/bids \
  -B ${QSIPREP_DIR}:/qsiprep_in \
  -B ${OUT_DIR}:/out \
  -B ${WORK_DIR}:/work \
  -B ${FS_LICENSE}:/li \
  ${SING_CONTAINER} \
dtifit -k ${QSIRECON_OUT}_dwi.nii.gz \
  -m ${QSIRECON_OUT}_mask.nii.gz \
  -r ${QSIRECON_OUT}_dwi.bvec \
  -b ${QSIRECON_OUT}_dwi.bval \
  --save_tensor --sse \
  -o /out/${DTIFIT_OUT}

##### STEP 3 - run the ENIGMA DTI participant workflow ########################

# ENIGMA_DTI_OUT=${OUT_DIR}/enigmaDTI

# mkdir -p ${ENIGMA_DTI_OUT}

# python ${CODE_DIR}/run_participant_enigma_extract.py --calc-all --debug \
# ${ENIGMA_DTI_OUT}/sub-${subject_id}_${session} ${DTIFIT_OUT}_FA.nii.gz


done
