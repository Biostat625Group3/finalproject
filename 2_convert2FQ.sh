#!/bin/bash

#SBATCH --mail-user=jeffrw@umich.edu # REPLACE THIS WITH YOUR EMAIL ADDRESS TO GET NOTIFIED OF JOB RUNS
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --nodes=1                 # Each task gets 1 node
#SBATCH --ntasks=1                # Each task is a single independent process
#SBATCH --cpus-per-task=32        # Use all 32 CPUs on each node
#SBATCH --mem=128G                # Memory per node/task
#SBATCH --time=08:00:00           # Maximum runtime
#SBATCH --array=0-8               # This will give a job to each node, where it is distributed based on below. May need to adjust this if resources are not available
#SBATCH --output=log/%x-%A_%a.log # Separate log for each task
#SBATCH --account=biostat625s001f24_class
#SBATCH --partition=standard

# Main directory where files are located

export MAIN_DIR=/scratch/biostat625s001f24_class_root/biostat625s001f24_class/shared_data/Group_3

source ${MAIN_DIR}/.path_vars

mkdir -p "${MAIN_DIR}/FASTQ"



# Get the full list of .sra files

SRA_FILES=(${MAIN_DIR}/sra/*.sra)
NUM_FILES=${#SRA_FILES[@]}  # Total number of files


# Total number of tasks (array elements)
ARRAY_COUNT=${SLURM_ARRAY_TASK_COUNT:-9}  # Defaults to 9 tasks

# Calculate the subset of files for this task
FILES_PER_TASK=$(( (NUM_FILES + ARRAY_COUNT - 1) / ARRAY_COUNT ))
START=$((SLURM_ARRAY_TASK_ID * FILES_PER_TASK))
END=$((START + FILES_PER_TASK))

if [ $END -gt $NUM_FILES ]; then
    END=$NUM_FILES
fi

# Log the task's assigned files
echo "Array Task $SLURM_ARRAY_TASK_ID processing files $START to $((END-1)) of $NUM_FILES." >> log/debug_${SLURM_ARRAY_TASK_ID}.log

# Loop through and process the assigned files
for (( i=START; i<END; i++ )); do
    
    sra_file="${SRA_FILES[$i]}"
    base_name=$(basename "$sra_file" .sra)
    echo "Processing $base_name on $(hostname)" >> log/debug_${SLURM_ARRAY_TASK_ID}.log

    # Convert .sra to .fastq
    if ! fasterq-dump --force --split-files --threads $SLURM_CPUS_PER_TASK --outdir "${MAIN_DIR}/FASTQ" "$sra_file"; then
        echo "Error converting $sra_file to FASTQ!" >> log/debug_${SLURM_ARRAY_TASK_ID}.log
        exit 1
    fi

    # Compress the resulting .fastq files
    if ! gzip -f "${MAIN_DIR}/FASTQ/${base_name}"_*.fastq; then
        echo "Error compressing FASTQ files for $base_name!" >> log/debug_${SLURM_ARRAY_TASK_ID}.log
        exit 1
    fi

    echo "Finished processing $base_name on $(hostname)" >> log/debug_${SLURM_ARRAY_TASK_ID}.log
done

# Task completion log
echo "Array Task $SLURM_ARRAY_TASK_ID completed all assigned files." >> log/debug_${SLURM_ARRAY_TASK_ID}.log


