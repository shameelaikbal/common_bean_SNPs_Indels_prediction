#downloading the 214 samples for which I have CBB data from NCBI-SRA  BioProject PRJNA1112458, Wiersma et al. (2024)

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

#once all the fastq files have been download, can do trimming using trimmomatic
# i have given this as an array, and to make it run smooth, i have got the SRR names in a batch_sample_list.txt first and ran the following
time srun -m block:block:block trimmomatic PE -threads 8 \
  ${SAMPLE}_1.fastq.gz ${SAMPLE}_2.fastq.gz \
  batch_trimmed_paired/${SAMPLE}_1_paired.fq.gz batch_trimmed_unpaired/${SAMPLE}_1_unpaired.fq.gz \
  batch_trimmed_paired/${SAMPLE}_2_paired.fq.gz batch_trimmed_unpaired/${SAMPLE}_2_unpaired.fq.gz \
  LEADING:10 TRAILING:10 SLIDINGWINDOW:4:15 MINLEN:40

#the trimming parameters i have followed Wiersma et al 2024

#next neeed to do index for bwa-mem2, samtools, and create a dict for gatk for next steps
module load bwa-mem2/2.2.1--hd03093a_2
bwa-mem2 index pangenome.fasta.gz #given as a job with 16 CPUs

module load samtools/1.15--h3843a85_0
samtools faidx pangenome.fasta.gz

 module load gatk4/4.2.5.0--hdfd78af_0
 gatk CreateSequenceDictionary -R pangenome.fasta.gz #given as a job

 #next step is bwa-mem2 alignent to the single reference genome or pangenome fasta and marking duplicates, given together in a single batchscript as array
 # Define base directory
BASE_DIR=

# Paths
# Set paths
REF=./pangenome.fasta.gz
FASTQ_DIR=$BASE_DIR
BAM_DIR=$BASE_DIR/dedup_bam
METRICS_DIR=$BASE_DIR/metrics
LOGS_DIR=$BASE_DIR/logs
SAMPLES=batch_sample_list.txt

# Create output directories if they don’t exist
mkdir -p "$BAM_DIR" "$METRICS_DIR" "$LOGS_DIR"

# Get sample name
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $SAMPLES)
RG="@RG\tID:${SAMPLE}\tSM:${SAMPLE}\tPL:ILLUMINA"

# Output file
SORTED_BAM=${SAMPLE}.sorted.bam

# Run alignment
echo "[$(date)] Starting BWA alignment for $SAMPLE"
bwa-mem2 mem -t 32 -M -R "$RG" \
  "$REF" \
  "$FASTQ_DIR/${SAMPLE}_1_paired.fq.gz" "$FASTQ_DIR/${SAMPLE}_2_paired.fq.gz" \
  2> "$LOGS_DIR/${SAMPLE}_bwa_mem2.log" | \
  samtools sort -@ 32 -o "$SORTED_BAM" \
  2> "$LOGS_DIR/${SAMPLE}_sort.log"

# Check if sorted BAM was created
if [[ ! -f "$SORTED_BAM" ]]; then
  echo "[$(date)] ERROR: Sorted BAM not created for $SAMPLE"
  exit 1
fi

# Run MarkDuplicates
echo "[$(date)] Running MarkDuplicates for $SAMPLE"
gatk MarkDuplicates \
  I="$SORTED_BAM" \
  O="$BAM_DIR/${SAMPLE}.dedup.bam" \
  M="$METRICS_DIR/${SAMPLE}.dup_metrics.txt" \
  2> "$LOGS_DIR/${SAMPLE}_markdup.log"

# Check if dedup BAM was created
if [[ ! -s "$BAM_DIR/${SAMPLE}.dedup.bam" ]]; then
  echo "[$(date)] ERROR: Dedup BAM not created for $SAMPLE"
  exit 1
fi

# Index the dedup BAM
echo "[$(date)] Indexing BAM for $SAMPLE"
samtools index "$BAM_DIR/${SAMPLE}.dedup.bam"

echo "[$(date)] Done for $SAMPLE"
 




