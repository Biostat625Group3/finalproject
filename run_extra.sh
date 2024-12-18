#!/bin/bash

#SBATCH --mail-user=jeffrw@umich.edu
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=08:00:00
#SBATCH --output=log/rerun_GSM7225035-%j.log
#SBATCH --account=biostat625s001f24_class
#SBATCH --partition=standard



# Main directory where files are located
export MAIN_DIR=/scratch/biostat625s001f24_class_root/biostat625s001f24_class/shared_data/Group_3

sample_dir="$MAIN_DIR/sample_concat"
output_dir="$MAIN_DIR/output"
ref_dir="$MAIN_DIR/ref_genome/refdata-gex-mm10-2020-A"



# Sample-specific variables
sample="GSM7225035"
r1_fastq="$sample_dir/${sample}_S1_L001_R1_001.fastq.gz"
dummy_r2="$sample_dir/${sample}_S1_L001_R2_001.fastq.gz"



# Check if cellranger is in PATH
if ! command -v cellranger &> /dev/null; then
  echo "Error: cellranger is not in your PATH. Load the module or update PATH."
  exit 1

fi



# Regenerate the dummy R2 file

echo "Regenerating dummy R2 file for $sample..."

if [ -f "$dummy_r2" ]; then
  rm "$dummy_r2"  # Remove the corrupted file
fi



zcat "$r1_fastq" | \
awk 'NR%4==1{print $1"/2"}; NR%4==2{print "NNNNNNNNNNNNNNNNNNNNNNNNN"}; NR%4==3{print "+"}; NR%4==0{print "!!!!!!!!!!!!!!!!!!!!!!!!!"}' | \
gzip > "$dummy_r2"



if [ $? -ne 0 ]; then
  echo "Error regenerating dummy R2 file for $sample."
  exit 1

fi



# Rerun cellranger count

echo "Rerunning cellranger count for $sample..."
cellranger count \
  --id=${sample}_count_fix \
  --create-bam=false \
  --transcriptome="$ref_dir" \
  --fastqs="$sample_dir" \
  --sample="$sample" \
  --chemistry=SC3Pv3 \
  --localcores=32 \
  --localmem=128



if [ $? -eq 0 ]; then
  echo "cellranger count completed successfully for $sample."

else
  echo "cellranger count failed again for $sample."
  exit 1

fi


