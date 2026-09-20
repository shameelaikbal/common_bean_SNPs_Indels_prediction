#downloading the 220 samples from NCBI

#get SRR_ID for this array task
SRR_ID=$(sed -n "${SLURM_ARRAY_TASK_ID}p" srr_list.txt)

#create SRA_Directory
SRA_DIR=$(pwd)
mkdir -p  sra

conda activate gatk_env 
#output directory for fasterq-dump
OUTPUT_DIR=file/path
mkdir -p "${OUTPUT_DIR}"

#output directory for gzipped
OUTPUT_ZIP=file/path
mkdir -p "${OUTPUT_ZIP}"

# Script to run (srun -m command recommended by Pawsey to pack threads)
time srun -m block:block:block prefetch "${SRR_ID}" --max-size u -O sra

#flatten files
cp sra/${SRR_ID}/${SRR_ID}.sra sra/${SRR_ID}.sra

#fasterq
time srun -m block:block:block fastq-dump \
        --split-files \
        --gzip \
        --outdir "${OUTPUT_DIR}" \
        sra/${SRR_ID}.sra

#gzip and move to zipped directory
cd "${OUTPUT_DIR}"
mv "${SRR_ID}"_*.fastq.gz "${OUTPUT_ZIP}"/
