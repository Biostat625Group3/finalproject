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

# Main directory where files are located
export MAIN_DIR=/scratch/biostat625s001f24_class_root/biostat625s001f24_class/shared_data/Group_3

# Create output directory
output_dir="$MAIN_DIR/output"
mkdir -p "$output_dir"

# Reference genome directory
ref_dir="$MAIN_DIR/ref_genome/refdata-gex-mm10-2020-A"

# Check if cellranger is in PATH
if ! command -v cellranger &> /dev/null; then
  echo "Error: cellranger is not in your PATH. Load the module or update PATH."
  exit 1

fi

# Create dummy R2 if not available
dummy_r2="$MAIN_DIR/concat_FASTQ/old_S1_L001_R2_001.fastq.gz"

if [ ! -f "$dummy_r2" ]; then
  zcat "$MAIN_DIR/concat_FASTQ/old_S1_L001_R1_001.fastq.gz" | \
  awk 'NR%4==1{print $1"/2"}; NR%4==2{print "NNNNNNNNNNNNNNNNNNNNNNNNN"}; NR%4==3{print "+"}; NR%4==0{print "!!!!!!!!!!!!!!!!!!!!!!!!!"}' | \
  gzip > "$dummy_r2"

fi

cellranger count \
  --id=old_sample \
  --create-bam=false \
  --transcriptome="$ref_dir" \
  --fastqs="$MAIN_DIR/concat_FASTQ" \
  --sample=old \
  --chemistry=SC3Pv3 \
  --localcores=32 \
  --localmem=128 \


