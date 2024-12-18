#!/bin/bash

#SBATCH --mail-user=jeffrw@umich.edu # REPLACE WITH YOUR EMAIL ADDRESS
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --nodes=1                 # Each task gets 1 node
#SBATCH --ntasks=1                # Each task is a single independent process
#SBATCH --cpus-per-task=32        # Use all 32 CPUs on each node
#SBATCH --mem=128G                # Memory per node/task
#SBATCH --time=08:00:00           # Maximum runtime
#SBATCH --array=0-5               # Use 6 tasks for 6 samples
#SBATCH --output=log/%x-%A_%a.log # Separate log for each task
#SBATCH --account=biostat625s001f24_class
#SBATCH --partition=standard

# Main directory where files are located

export MAIN_DIR=/scratch/biostat625s001f24_class_root/biostat625s001f24_class/shared_data/Group_3

# Navigate to the FASTQ directory
cd "${MAIN_DIR}/FASTQ" 

# Create a new directory for concatenated sample files
sample_concat="${MAIN_DIR}/sample_concat"
mkdir -p "${sample_concat}"

# Mapping of run_ID to sample_ID and sample labels
declare -A SAMPLE_MAP=(
  [SRR24293029]=GSM7225039 [SRR24293030]=GSM7225039 [SRR24293031]=GSM7225039 [SRR24293032]=GSM7225039
  [SRR24293033]=GSM7225038 [SRR24293034]=GSM7225038 [SRR24293035]=GSM7225038 [SRR24293036]=GSM7225038
  [SRR24293037]=GSM7225037 [SRR24293038]=GSM7225037 [SRR24293039]=GSM7225037 [SRR24293040]=GSM7225037
  [SRR24293041]=GSM7225037 [SRR24293042]=GSM7225037 [SRR24293043]=GSM7225037 [SRR24293044]=GSM7225036
  [SRR24293045]=GSM7225036 [SRR24293046]=GSM7225036 [SRR24293047]=GSM7225036 [SRR24293048]=GSM7225037
  [SRR24293049]=GSM7225035 [SRR24293050]=GSM7225035 [SRR24293051]=GSM7225035 [SRR24293052]=GSM7225035
  [SRR24293053]=GSM7225037 [SRR24293054]=GSM7225034 [SRR24293055]=GSM7225034 [SRR24293056]=GSM7225034
  [SRR24293057]=GSM7225034 [SRR24293058]=GSM7225034 [SRR24293059]=GSM7225034 [SRR24293060]=GSM7225034
  [SRR24293061]=GSM7225034 [SRR24293062]=GSM7225034
)



# Mapping of sample_ID to group and labels
declare -A SAMPLE_LABELS=(
  [GSM7225034]=YW1
  [GSM7225035]=YW2
  [GSM7225036]=YW3
  [GSM7225037]=OW1
  [GSM7225038]=OW2
  [GSM7225039]=OW3
)

# Get the sample_ID corresponding to the SLURM_ARRAY_TASK_ID
SAMPLE_IDS=(GSM7225034 GSM7225035 GSM7225036 GSM7225037 GSM7225038 GSM7225039)
current_sample_id=${SAMPLE_IDS[${SLURM_ARRAY_TASK_ID}]}
current_label=${SAMPLE_LABELS[${current_sample_id}]}

# Initialize an array to store files for the current sample
sample_files=()

# Loop through the FASTQ files and collect those matching the current sample_ID
for file in *_3.fastq.gz; do
  base_name="${file%%_*}"
  sample_id="${SAMPLE_MAP[$base_name]}"

  if [[ $sample_id == "$current_sample_id" ]]; then
    sample_files+=("$file")

  fi

done

# Concatenate files for the current sample_ID
if [[ ${#sample_files[@]} -gt 0 ]]; then
  zcat "${sample_files[@]}" | gzip > "${sample_concat}/${current_sample_id}_${current_label}.fastq.gz"

fi


