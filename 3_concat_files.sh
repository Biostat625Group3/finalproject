#!/bin/bash

#SBATCH --mail-user=jeffrw@umich.edu # REPLACE THIS WITH YOUR EMAIL ADDRESS TO GET NOTIFIED OF JOB RUNS
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --nodes=1                 # Each task gets 1 node
#SBATCH --ntasks=1                # Each task is a single independent process
#SBATCH --cpus-per-task=32        # Use all 32 CPUs on each node
#SBATCH --mem=128G                # Memory per node/task
#SBATCH --time=08:00:00           # Maximum runtime
#SBATCH --array=0-1               # Use 2 tasks: one for young, one for old
#SBATCH --output=log/%x-%A_%a.log # Separate log for each task
#SBATCH --account=biostat625s001f24_class
#SBATCH --partition=standard

# Main directory where files are located
export MAIN_DIR=/scratch/biostat625s001f24_class_root/biostat625s001f24_class/shared_data/Group_3

# Navigate to the FASTQ directory
cd "$MAIN_DIR/FASTQ" || { echo "FASTQ directory not found!"; exit 1; }

# Create a new directory for concatenated files
concat_dir="$MAIN_DIR/concat_FASTQ"
mkdir -p "$concat_dir"

# Mapping of runs to groups
declare -A GROUP_MAP=(
  [SRR24293029]=O [SRR24293030]=O [SRR24293031]=O [SRR24293032]=O
  [SRR24293033]=O [SRR24293034]=O [SRR24293035]=O [SRR24293036]=O
  [SRR24293037]=O [SRR24293038]=O [SRR24293039]=O [SRR24293040]=O
  [SRR24293041]=O [SRR24293042]=O [SRR24293043]=O [SRR24293044]=Y
  [SRR24293045]=Y [SRR24293046]=Y [SRR24293047]=Y [SRR24293048]=O
  [SRR24293049]=Y [SRR24293050]=Y [SRR24293051]=Y [SRR24293052]=Y
  [SRR24293053]=O [SRR24293054]=Y [SRR24293055]=Y [SRR24293056]=Y
  [SRR24293057]=Y [SRR24293058]=Y [SRR24293059]=Y [SRR24293060]=Y
  [SRR24293061]=Y [SRR24293062]=Y
)

# Initialize files for concatenation
young_files=()
old_files=()

# Loop through the files in the FASTQ directory
for file in *_3.fastq.gz; do
  base_name="${file%%_*}"
  group="${GROUP_MAP[$base_name]}"

  if [[ $group == "Y" ]]; then
    young_files+=("$file")

  elif [[ $group == "O" ]]; then
    old_files+=("$file")

  fi

done

# Determine which group to process based on the SLURM_ARRAY_TASK_ID
if [[ $SLURM_ARRAY_TASK_ID -eq 0 ]]; then

  # Concatenate files for young group
  if [[ ${#young_files[@]} -gt 0 ]]; then
    echo "Concatenating files for young group..."
    zcat "${young_files[@]}" | gzip > "$concat_dir/young.fastq.gz"

  else
    echo "No files found for young group."

  fi

elif [[ $SLURM_ARRAY_TASK_ID -eq 1 ]]; then

  # Concatenate files for old group
  if [[ ${#old_files[@]} -gt 0 ]]; then
    echo "Concatenating files for old group..."
    zcat "${old_files[@]}" | gzip > "$concat_dir/old.fastq.gz"

  else
    echo "No files found for old group."

  fi

else
  echo "Invalid SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"
  exit 1

fi

# Completion message

echo "Concatenation complete. Output stored in $concat_dir."


