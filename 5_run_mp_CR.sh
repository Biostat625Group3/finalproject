#!/bin/bash

#SBATCH --mail-user=jeffrw@umich.edu
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=08:00:00
#SBATCH --output=log/%x-%A_%a.log
#SBATCH --account=biostat625s001f24_class
#SBATCH --partition=standard
#SBATCH --array=0-5                          # Job array (6 tasks: 0-5)


# Main directory where files are located
export MAIN_DIR=/scratch/biostat625s001f24_class_root/biostat625s001f24_class/shared_data/Group_3
sample_dir="$MAIN_DIR/sample_concat"
output_dir="$MAIN_DIR/output"
ref_dir="$MAIN_DIR/ref_genome/refdata-gex-mm10-2020-A"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# List of sample prefixes (without _R1_001.fastq.gz)
samples=(
    "GSM7225034"
    "GSM7225035"
    "GSM7225036"
    "GSM7225037"
    "GSM7225038"
    "GSM7225039"
)

# Select sample based on SLURM_ARRAY_TASK_ID
sample=${samples[$SLURM_ARRAY_TASK_ID]}

# Paths to R1 and dummy R2
r1_fastq="$sample_dir/${sample}_S1_L001_R1_001.fastq.gz"
dummy_r2="$sample_dir/${sample}_S1_L001_R2_001.fastq.gz"

# Check if cellranger is in PATH
if ! command -v cellranger &> /dev/null; then
  echo "Error: cellranger is not in your PATH. Load the module or update PATH."
  exit 1

fi

# Create dummy R2 if it doesn't exist
if [ ! -f "$dummy_r2" ]; then
  zcat "$r1_fastq" | \
  awk 'NR%4==1{print $1"/2"}; NR%4==2{print "NNNNNNNNNNNNNNNNNNNNNNNNN"}; NR%4==3{print "+"}; NR%4==0{print "!!!!!!!!!!!!!!!!!!!!!!!!!"}' | \
  gzip > "$dummy_r2"

fi

# Run cellranger count for the selected sample
cellranger count \
  --id=${sample}_count \
  --create-bam=false \
  --transcriptome="$ref_dir" \
  --fastqs="$sample_dir" \
  --sample="$sample" \
  --chemistry=SC3Pv3 \
  --localcores=32 \
  --localmem=128

