#!/bin/bash

###################################################### SET-UP STEPS ####################################################################

## ----------------------------------------------
## PRE-STEP 1: Argument calling
## ----------------------------------------------

## Check if SRA ID arguments are provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <Run_ID>"
    exit 1
fi

ID="$1"  ## The Run ID provided as an argument

## ----------------------------------------------
## PRE-STEP 2: Directory/parameter setting
## ----------------------------------------------

results="PATHTORESULTSFOLDER"
threads=16
DBNAME="KRAKEN2DBNAME"
dbs="EndoFUN_v1.7"
metaphlan_db="PATHTOMETAPHLAN4DB"
lineages=("fungi_odb10" "bacteria_odb10")

LOGFILE="${results}/process.log"
mkdir -p "$(dirname "$LOGFILE")"

## ----------------------------------------------
## PRE-STEP 3: Function defining
## ----------------------------------------------

# Function for running FastQC
run_fastqc() {
    local input_file="$1"
    local output_dir="$2"
    echo "FastQC: Processing ${input_file}..."
    fastqc "${input_file}" -o "${output_dir}" --threads "${threads}"
}

log_run() {
    local run_id=$1
    local status=$2
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${run_id}\t${timestamp}\t${status}" >> "$LOGFILE"
}

## ----------------------------------------------
## PRE-STEP 4: Download SRA sample
## ----------------------------------------------

conda activate SRA_download

echo "Pre-step 4: Downloading SRA data for Run: ${ID}..."
cd ${results}

mkdir ${ID}
cd ${ID}
fasterq-dump --split-files ${ID}
cd ..
echo "Pre-step 4: Download completed"

conda deactivate
###################################################### GENOME ASSEMBLY STEPS ####################################################################

## Run with: while read srr; do sbatch Endo_hunt_BLAST.sh "$srr"; done < input_srr_list.txt

## ----------------------------------------------
## STEP 1: Read QC: Run FastQC 
## ----------------------------------------------
conda activate Assembly

echo "Step 1: Running initial read QC..."

# Create a directory for QC results and parent ${results}/${ID} directory
mkdir -p ${results}/${ID}/fastqc_1

# Iterate over forward and reverse reads - fastqc_1
for read_type in 1 2; do
    run_fastqc "${results}/${ID}/${ID}_${read_type}.fastq" "${results}/${ID}/fastqc_1"
done

input_filename_1="${results}/${ID}/${ID}_1.fastq"
input_filename_2="${results}/${ID}/${ID}_2.fastq"

## ----------------------------------------------
## STEP 2: Read cleanup: Trimmomatic
## ----------------------------------------------

# Run Trimmomatic with quality trimming and adapter clipping
echo "Step 2: Running Trimmomatic..."
trimmomatic PE -threads ${threads} ${input_filename_1} ${input_filename_2} ${results}/${ID}/${ID}_trimmed_paired_1.fq ${results}/${ID}/${ID}_trimmed_unpaired_1.fq ${results}/${ID}/${ID}_trimmed_paired_2.fq ${results}/${ID}/${ID}_trimmed_unpaired_2.fq ILLUMINACLIP:TruSeq3-PE-2.fa:2:30:10:2:True LEADING:20 TRAILING:20 SLIDINGWINDOW:5:20 MINLEN:50

echo "Step 2.5: Running post-read cleanup QC..."
# Create a directory for QC results
mkdir ${results}/${ID}/fastqc_2

# Iterate over forward and reverse reads - fastqc_2
for read_type in 1 2; do
    run_fastqc "${results}/${ID}/${ID}_trimmed_paired_${read_type}.fq" "${results}/${ID}/fastqc_2"
done

## ----------------------------------------------
## STEP 3: Metagenomics classifications of reads: Kraken2
## ----------------------------------------------
conda activate Kraken2Krona

echo "Running Kraken2 identification, database = ${DBNAME}..."
mkdir -p ${results}/${ID}/Kraken2_reads_${dbs}/Kraken2

kraken2 --db $DBNAME --threads 16 --confidence 0.05 --report ${results}/${ID}/Kraken2_reads_${dbs}/Kraken2/${ID}.k2report --paired ${results}/${ID}/${ID}_trimmed_paired_1.fq ${results}/${ID}/${ID}_trimmed_paired_2.fq > ${results}/${ID}/Kraken2_reads_${dbs}/Kraken2/${ID}.kraken2

kraken_read_output="${results}/${ID}/Kraken2_reads_${dbs}/Kraken2/${ID}.k2report"
echo "Kraken2 identification of reads complete"

conda activate MetaPhiAn4

echo "Running MetaPhlAn identification..."
mkdir -p ${results}/${ID}/MetaPhlAn_results
metaphlan ${results}/${ID}/${ID}_trimmed_paired_1.fq,${results}/${ID}/${ID}_trimmed_paired_2.fq --index mpa_vJun23_CHOCOPhlAnSGB_202403 --bowtie2db ${metaphlan_db} --bowtie2out ${results}/${ID}/${ID}_metaphlan.bowtie2.bz2 -t rel_ab_w_read_stats --nproc ${threads} --input_type fastq -o ${results}/${ID}/MetaPhlAn_results/${ID}_metaphlan.txt
echo "MetaPhlAn identification of reads complete"

## ----------------------------------------------
## STEP 3.5: Kraken2 Mycetohabitans check
## ----------------------------------------------

# Extract number of reads assigned to Mycetohabitans
kraken2_myceto_reads=$(awk '$6 == "Mycetohabitans" {print $2; exit}' "$kraken_read_output")
echo "Number of reads assigned to Mycetohabitans: $kraken2_myceto_reads"

# Check if reads are greater than 1000
if [ "$kraken2_myceto_reads" -gt 1000 ]; then
    echo "More than 1000 reads found for Mycetohabitans. Continuing..."
    log_run "${ID}" "Detected Mycetohabitans: with $kraken2_myceto_reads reads"
else
    echo "Fewer than 1000 reads for Mycetohabitans. Exiting."
    log_run "${ID}" "Not detected: Insufficient (<1000) Mycetohabitans reads"
    rm -rf ${results}/${ID}  # Remove the results directory for this ID
    exit 1
fi

## ----------------------------------------------
## STEP 4: Assembly: SPAdes
## ----------------------------------------------
conda activate Assembly

echo "Step 4: Running SPAdes assembly with ML optimisation..."
spades.py --meta -1 ${results}/${ID}/${ID}_trimmed_paired_1.fq -2 ${results}/${ID}/${ID}_trimmed_paired_2.fq -o ${results}/${ID}/SPAdes

if [ -f "${results}/${ID}/SPAdes/scaffolds.fasta" ]; then
    echo "Step 4.2: Extracting scaffolds >500bp..."
    seqkit seq -m 500 ${results}/${ID}/SPAdes/scaffolds.fasta > ${results}/${ID}/SPAdes/scaffolds_500.fasta

    conda deactivate
    conda activate AssemblyQC

    echo "Step 4.3: Running assembly QUAST"
    mkdir ${results}/${ID}/QC_500
    quast ${results}/${ID}/SPAdes/scaffolds_500.fasta -o ${results}/${ID}/QC_500 --threads ${threads}
fi

conda deactivate

## ----------------------------------------------
## STEP 4.5: Identify bacterial contigs with BLAST
## ----------------------------------------------
conda activate BLAST

echo "Step 4.5: Mapping contigs to bacterial reference genomes with BLAST..."

#Make a BLAST db of the NCBI GenBank 'Complete' level Mycetohabitans genomes

BLAST_DB="PATHTO/mycetohabitans_blast_db"
CONTIGS="${results}/${ID}/SPAdes/contigs.fasta"
BLAST_OUTPUT="${results}/${ID}/${ID}_contigs_vs_bactdb.blast.out"
HITS_FILE="${results}/${ID}/${ID}_bacterial_contigs.txt"

echo "Running BLAST on contigs..."
blastn -task megablast \
       -query "$CONTIGS" \
       -db "$BLAST_DB" \
       -out "$BLAST_OUTPUT" \
       -evalue 1e-10 \
       -perc_identity 70 \
       -outfmt '6 qseqid sseqid pident length evalue bitscore qcovs' \
       -num_threads $threads

echo "Filtering contigs with significant BLAST hits..."
# Threshold filter (already done)
awk '$3 >= 70 && $4 >= 500 && $7 >= 50 {print $1}' "$BLAST_OUTPUT" | sort -u > "$HITS_FILE"

# Define outputs
FILTERED_CONTIGS="${results}/${ID}/${ID}_bacterial_contigs.fasta"
NONBACT_CONTIGS="${results}/${ID}/${ID}_nonbacterial_contigs.fasta"

conda deactivate
conda activate seqkit

# Extract bacterial contigs (with BLAST hits passing thresholds)
seqkit grep -f "$HITS_FILE" "$CONTIGS" > "$FILTERED_CONTIGS"

# Extract everything else (unaligned/non-bacterial)
seqkit grep -f "$HITS_FILE" -v "$CONTIGS" > "$NONBACT_CONTIGS"

echo "Bacterial contigs: $FILTERED_CONTIGS"
echo "Non-bacterial contigs: $NONBACT_CONTIGS"

conda deactivate

## ----------------------------------------------
## STEP 4.56: Kraken2 classification of contig bins (bacterial vs non-bacterial)
## ----------------------------------------------
conda activate Kraken2Krona

mkdir -p ${results}/${ID}/Kraken2_contigs_${dbs}/bacterial
mkdir -p ${results}/${ID}/Kraken2_contigs_${dbs}/nonbacterial

# Bacterial bin
kraken2 --db $DBNAME --threads ${threads} --confidence 0.3 \
  --report ${results}/${ID}/Kraken2_contigs_${dbs}/bacterial/${ID}.bact.k2report \
  ${results}/${ID}/${ID}_bacterial_contigs.fasta \
  > ${results}/${ID}/Kraken2_contigs_${dbs}/bacterial/${ID}.bact.kraken2

# Non-bacterial bin
kraken2 --db $DBNAME --threads ${threads} --confidence 0.3 \
  --report ${results}/${ID}/Kraken2_contigs_${dbs}/nonbacterial/${ID}.nonbact.k2report \
  ${results}/${ID}/${ID}_nonbacterial_contigs.fasta \
  > ${results}/${ID}/Kraken2_contigs_${dbs}/nonbacterial/${ID}.nonbact.kraken2

conda deactivate

## ----------------------------------------------
## STEP 4.6: QUAST and BUSCO for bacterial contigs
## ----------------------------------------------
conda activate AssemblyQC

echo "Step 4.6: Running QUAST on bacterial contigs..."
mkdir -p ${results}/${ID}/QC_bacteria
quast ${results}/${ID}/${ID}_bacterial_contigs.fasta \
     -o ${results}/${ID}/QC_bacteria --threads ${threads}

conda deactivate
conda activate BUSCO

echo "Step 4.6: Running BUSCO (bacteria_odb10) on bacterial contigs..."
cd "${results}/${ID}"
busco -i ${results}/${ID}/${ID}_bacterial_contigs.fasta \
      -l "PATHTO/BUSCO_lineages/bacteria_odb10" \
      -o "BUSCO_bacterial_only_bacteriaodb10" -m genome
busco -i ${results}/${ID}/${ID}_bacterial_contigs.fasta \
      -l "PATHTO/BUSCO_lineages/fungi_odb10" \
      -o "BUSCO_bacterial_only_fungiodb10" -m genome
cd ..
cd ..
conda deactivate

## ----------------------------------------------
## STEP 4.7: QUAST & BUSCO for non-bacterial contigs (likely fungal/other)
## ----------------------------------------------
conda activate AssemblyQC

echo "Running QUAST on non-bacterial contigs..."
mkdir -p ${results}/${ID}/QC_nonbacterial
quast ${results}/${ID}/${ID}_nonbacterial_contigs.fasta \
     -o ${results}/${ID}/QC_nonbacterial --threads ${threads}

conda deactivate
conda activate BUSCO

echo "Running BUSCO (fungi_odb10) on non-bacterial contigs..."
cd "${results}/${ID}"
busco -i ${results}/${ID}/${ID}_nonbacterial_contigs.fasta \
      -l "PATHTO/BUSCO_lineages/fungi_odb10" \
      -o "BUSCO_nonbacterial_only_fungiodb10_${ID}" -m genome
busco -i ${results}/${ID}/${ID}_nonbacterial_contigs.fasta \
      -l "PATHTO/BUSCO_lineages/bacteria_odb10" \
      -o "BUSCO_nonbacterial_only_bacterialodb10_${ID}" -m genome
cd ..
cd ..
conda deactivate

## ----------------------------------------------
## STEP 5: Fungal classificaiton: ITSx extraction
## ----------------------------------------------
conda activate ITSx

echo "Running ITSx assessment..."
mkdir ${results}/${ID}/${ID}_ITSx

cd ${results}/${ID}/${ID}_ITSx
if [ -f "${results}/${ID}/SPAdes/scaffolds_500.fasta" ]; then
    ITSx -i ${results}/${ID}/SPAdes/scaffolds_500.fasta -o ${ID}_ITSx -t F
elif [ -f "${results}/${ID}/SPAdes/contigs.fasta" ]; then
    ITSx -i ${results}/${ID}/SPAdes/contigs.fasta -o ${ID}_ITSx -t F
else
    echo "Error: Neither scaffolds_500.fasta nor contigs.fasta found in ${results}/${ID}/SPAdes/"
fi

echo "ITSx assessment complete"
conda deactivate
## ----------------------------------------------
## STEP 6: Metagenomics classifications: Kraken2
## ----------------------------------------------
conda activate Kraken2Krona

echo "Running Kraken2 identification, database = ${DBNAME}..."
mkdir -p ${results}/${ID}/Kraken2_metagenome_${dbs}/Kraken2

if [ -f "${results}/${ID}/SPAdes/scaffolds_500.fasta" ]; then
    kraken2 --db $DBNAME --threads 16 --confidence 0.3 --report ${results}/${ID}/Kraken2_metagenome_${dbs}/Kraken2/${ID}.k2report ${results}/${ID}/SPAdes/scaffolds_500.fasta > ${results}/${ID}/Kraken2_metagenome_${dbs}/Kraken2/${ID}.kraken2
elif [ -f "${results}/${ID}/SPAdes/contigs.fasta" ]; then
    kraken2 --db $DBNAME --threads 16 --confidence 0.3 --report ${results}/${ID}/Kraken2_metagenome_${dbs}/Kraken2/${ID}.k2report ${results}/${ID}/SPAdes/contigs.fasta > ${results}/${ID}/Kraken2_metagenome_${dbs}/Kraken2/${ID}.kraken2
else
    echo "Error: Neither scaffolds_500.fasta nor contigs.fasta found in ${results}/${ID}/SPAdes/"
fi

kraken_output="${results}/${ID}/Kraken2_metagenome_${dbs}/Kraken2/${ID}.k2report"
echo "Kraken2 identification complete"

## ----------------------------------------------
## STEP 7: Generate Krona plots
## ----------------------------------------------
conda activate Kraken2Krona

echo "Generating Krona plot..."
## Generate Krona plot from Kraken output
mkdir ${results}/${ID}/Kraken2_metagenome_${dbs}/Krona
ktImportTaxonomy -t 5 -m 3 -o ${results}/${ID}/Kraken2_metagenome_${dbs}/Krona/${ID}_krona.html $kraken_output

echo "Krona plot generation complete"
conda deactivate
