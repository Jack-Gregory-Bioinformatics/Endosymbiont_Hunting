# Endosymbiont_Hunting

## Overview

`Endo_hunt_BLAST.sh` is an automated metagenomic screening and assembly pipeline for detecting putative **Mycetohabitans-associated bacterial genomes** in paired-end fungal SRA sequencing datasets.

The pipeline was developed to mine public fungal genome sequencing libraries for hidden bacterial symbiont signal. Given a single SRA Run ID, it downloads the reads, performs read quality control and trimming, screens reads for **Mycetohabitans**, conditionally proceeds to metagenomic assembly, separates putative bacterial and non-bacterial contigs, and generates taxonomic and assembly-quality summaries.

The workflow is intended for **HPC environments**, particularly SLURM-based systems, and can be run either sample-by-sample or as a batch submission.

---

## Repository contents

This repository contains:

- `Endo_hunt_BLAST.sh`  
  Main endosymbiont-hunting pipeline.

- `*.yaml`  
  Conda environment files required by the pipeline.

---

## Pipeline summary

For each SRA Run ID, the pipeline performs the following steps:

1. **Download SRA reads**
   - Uses `fasterq-dump --split-files`.
   - Expects paired-end reads named:
     - `<Run_ID>_1.fastq`
     - `<Run_ID>_2.fastq`

2. **Initial read quality control**
   - Runs FastQC on raw paired-end reads.

3. **Read trimming**
   - Uses Trimmomatic for adapter removal and quality filtering.
   - Retains paired trimmed reads for downstream analysis.

4. **Post-trimming QC**
   - Runs FastQC on trimmed paired reads.

5. **Read-level taxonomic screening**
   - Uses Kraken2 and MetaPhlAn4 to classify reads.
   - Extracts the number of Kraken2 reads assigned to `Mycetohabitans`.

6. **Conditional Mycetohabitans filtering**
   - Samples with more than 1,000 reads assigned to `Mycetohabitans` continue.
   - Samples below this threshold are logged and removed.

7. **Metagenomic assembly**
   - Uses metaSPAdes to assemble trimmed paired-end reads.
   - Filters scaffolds to retain sequences longer than 500 bp.
   - Runs QUAST on the filtered assembly.

8. **Identification of putative bacterial contigs**
   - Uses BLASTn against a curated Mycetohabitans reference database.
   - Retains contigs with:
     - >=70% nucleotide identity
     - >=500 bp alignment length
     - >=50% query coverage

9. **Separation of bacterial and non-bacterial contigs**
   - Uses `seqkit grep` to split the assembly into:
     - Putative bacterial contigs
     - Non-bacterial contigs, typically fungal or other non-target sequence

10. **Contig-level taxonomic classification**
    - Runs Kraken2 separately on bacterial and non-bacterial contig sets.

11. **Assembly quality assessment**
    - Runs QUAST and BUSCO on bacterial contigs.
    - Runs QUAST and BUSCO on non-bacterial contigs.

12. **Fungal ITS extraction**
    - Uses ITSx to extract fungal ITS regions from the metagenomic assembly.

13. **Metagenome-level Kraken2 classification**
    - Runs Kraken2 on assembled contigs or scaffolds.

14. **Krona visualisation**
    - Generates interactive Krona plots from Kraken2 results.

---

## Requirements

The pipeline assumes a Linux/HPC environment with Conda available.

Required software is provided through the included `.yaml` environment files and includes:

- SRA Toolkit
- FastQC
- Trimmomatic
- Kraken2
- Krona
- MetaPhlAn4
- SPAdes / metaSPAdes
- QUAST
- BUSCO
- BLAST+
- seqkit
- ITSx

The script uses multiple Conda environments, including:

- `SRA_download`
- `Assembly`
- `Kraken2Krona`
- `MetaPhiAn4`
- `BLAST`
- `seqkit`
- `AssemblyQC`
- `BUSCO`
- `ITSx`

Make sure the environment names in the `.yaml` files match the names called by the script.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/Endosymbiont_Hunting.git
cd Endosymbiont_Hunting
```

Create the Conda environments:

```bash
for env in *.yaml; do
  conda env create -f "$env"
done
```

Alternatively, using `mamba`:

```bash
for env in *.yaml; do
  mamba env create -f "$env"
done
```

---

## Database setup

Before running the pipeline, the following databases must be available.

### Kraken2 database

The script expects a Kraken2 database specified by:

```bash
DBNAME="KRAKEN2DBNAME"
```

Update this variable in the script to point to your Kraken2 database.

Example:

```bash
DBNAME="/path/to/kraken2/EndoFUN_v1.7"
```

The database used in this pipeline should contain bacterial and fungal reference sequences suitable for detecting **Mycetohabitans** and host-associated sequence.

### MetaPhlAn4 database

Update the MetaPhlAn database path:

```bash
metaphlan_db="PATHTOMETAPHLAN4DB"
```

Example:

```bash
metaphlan_db="/path/to/metaphlan_databases"
```

### Mycetohabitans BLAST database

The pipeline uses a curated BLAST database of complete public **Mycetohabitans** genomes to identify putative bacterial contigs.

Update:

```bash
BLAST_DB="PATHTO/mycetohabitans_blast_db"
```

Example database construction:

```bash
makeblastdb \
  -in mycetohabitans_reference_genomes.fasta \
  -dbtype nucl \
  -out mycetohabitans_blast_db
```

---

## Configuration

Before running, edit the following variables near the top of `Endo_hunt_BLAST.sh`:

```bash
results="PATHTORESULTSFOLDER"
threads=16
DBNAME="KRAKEN2DBNAME"
dbs="EndoFUN_v1.7"
metaphlan_db="PATHTOMETAPHLAN4DB"
```

Also update the BUSCO lineage paths:

```text
PATHTO/BUSCO_lineages/bacteria_odb10
PATHTO/BUSCO_lineages/fungi_odb10
```

And the Mycetohabitans BLAST database path:

```bash
BLAST_DB="PATHTO/mycetohabitans_blast_db"
```

---

## Usage

Run the pipeline on a single SRA Run ID:

```bash
bash Endo_hunt_BLAST.sh <Run_ID>
```

Example:

```bash
bash Endo_hunt_BLAST.sh SRR12345678
```

For SLURM submission:

```bash
sbatch Endo_hunt_BLAST.sh SRR12345678
```

For batch processing from a list of SRA Run IDs:

```bash
while read srr; do
  sbatch Endo_hunt_BLAST.sh "$srr"
done < input_srr_list.txt
```

The input file should contain one SRA Run ID per line:

```text
SRR12345678
SRR12345679
SRR12345680
```

---

## Output structure

For each run, the pipeline creates a sample-specific directory:

```text
results/
└── <Run_ID>/
    ├── fastqc_1/
    ├── fastqc_2/
    ├── Kraken2_reads_EndoFUN_v1.7/
    ├── MetaPhlAn_results/
    ├── SPAdes/
    ├── QC_500/
    ├── <Run_ID>_bacterial_contigs.fasta
    ├── <Run_ID>_nonbacterial_contigs.fasta
    ├── Kraken2_contigs_EndoFUN_v1.7/
    ├── QC_bacteria/
    ├── QC_nonbacterial/
    ├── BUSCO_bacterial_only_bacteriaodb10/
    ├── BUSCO_bacterial_only_fungiodb10/
    ├── BUSCO_nonbacterial_only_fungiodb10_<Run_ID>/
    ├── BUSCO_nonbacterial_only_bacterialodb10_<Run_ID>/
    ├── <Run_ID>_ITSx/
    └── Kraken2_metagenome_EndoFUN_v1.7/
```

---

## Key output files

### Read-level classification

```text
Kraken2_reads_EndoFUN_v1.7/Kraken2/<Run_ID>.k2report
Kraken2_reads_EndoFUN_v1.7/Kraken2/<Run_ID>.kraken2
MetaPhlAn_results/<Run_ID>_metaphlan.txt
```

These files summarise taxonomic signal in the trimmed reads.

### Assembly files

```text
SPAdes/contigs.fasta
SPAdes/scaffolds.fasta
SPAdes/scaffolds_500.fasta
```

`scaffolds_500.fasta` contains assembled scaffolds longer than 500 bp.

### Putative bacterial and non-bacterial contigs

```text
<Run_ID>_bacterial_contigs.fasta
<Run_ID>_nonbacterial_contigs.fasta
```

These files are generated by BLAST-based separation of contigs using the Mycetohabitans reference database.

### Bacterial contig BLAST results

```text
<Run_ID>_contigs_vs_bactdb.blast.out
<Run_ID>_bacterial_contigs.txt
```

The `.blast.out` file contains full BLAST tabular output.  
The `.txt` file contains the contig IDs passing the bacterial-contig filtering thresholds.

### Assembly quality reports

```text
QC_500/
QC_bacteria/
QC_nonbacterial/
```

These directories contain QUAST reports for the whole assembly, bacterial contigs, and non-bacterial contigs.

### BUSCO reports

BUSCO is run on both bacterial and non-bacterial contig sets using both bacterial and fungal lineage datasets. This allows assessment of whether the separated contig bins are enriched for bacterial or fungal single-copy orthologues.

### ITSx output

```text
<Run_ID>_ITSx/
```

Contains ITS regions extracted from the assembled fungal/metagenomic contigs.

### Krona plot

```text
Kraken2_metagenome_EndoFUN_v1.7/Krona/<Run_ID>_krona.html
```

Interactive taxonomic visualisation of the assembled metagenome classification.

---

## Mycetohabitans filtering criterion

After Kraken2 read-level classification, the pipeline extracts the number of reads assigned to:

```text
Mycetohabitans
```

Samples are retained only if they contain more than 1,000 reads assigned to Mycetohabitans.

This threshold is used as an initial screening step to prioritise datasets with sufficient bacterial signal for assembly and downstream analysis.

Samples below this threshold are logged and removed:

```text
process.log
```

---

## Log file

The pipeline writes a simple tab-delimited log file:

```text
process.log
```

Example entries:

```text
SRR12345678    2026-04-27 12:10:30    Detected Mycetohabitans: with 5432 reads
SRR12345679    2026-04-27 12:45:12    Not detected: Insufficient (<1000) Mycetohabitans reads
```

---

## Notes and assumptions

This pipeline is designed for paired-end Illumina SRA datasets.

It assumes that SRA reads can be downloaded using:

```bash
fasterq-dump --split-files
```

and that the resulting files are named:

```text
<Run_ID>_1.fastq
<Run_ID>_2.fastq
```

The pipeline identifies **putative Mycetohabitans-associated bacterial contigs** from metagenomic fungal sequencing datasets. Detection of Mycetohabitans reads or contigs should be interpreted as genome-based evidence for bacterial signal in the dataset, not direct experimental confirmation of intracellular localisation.

Experimental validation of endosymbiosis would require approaches such as microscopy, fluorescence in situ hybridisation, bacterial re-isolation, or targeted validation from the original fungal strain.

---

## Troubleshooting

### Conda environment not found

Check that the environment names in the `.yaml` files match the names used in the script.

List available environments:

```bash
conda env list
```

### Kraken2 database not found

Check that `DBNAME` points to a valid Kraken2 database directory.

```bash
kraken2-inspect --db /path/to/database
```

### BUSCO lineage not found

Check the paths to:

```text
bacteria_odb10
fungi_odb10
```

and update the BUSCO commands in the script accordingly.

### No bacterial contigs recovered

This may occur if:

- Mycetohabitans read abundance is low
- Assembly quality is poor
- Bacterial contigs are fragmented
- The BLAST reference database is too narrow
- The contig does not meet the identity, length, or coverage thresholds

The current BLAST filtering thresholds are:

```text
percent identity >= 70
alignment length >= 500 bp
query coverage >= 50
```

These can be modified in:

```bash
awk '$3 >= 70 && $4 >= 500 && $7 >= 50 {print $1}'
```

---

## Recommended script checks before running

Before large-scale batch submission, check the following paths and settings:

```bash
results="PATHTORESULTSFOLDER"
DBNAME="KRAKEN2DBNAME"
metaphlan_db="PATHTOMETAPHLAN4DB"
BLAST_DB="PATHTO/mycetohabitans_blast_db"
```

Also confirm that these directories are created consistently:

```text
Kraken2_metagenome_${dbs}
Kraken2_genome_${dbs}
```

In the current script, the metagenome Kraken2 output directory is created as:

```bash
Kraken2_metagenome_${dbs}
```

but the `.kraken2` output is redirected to:

```bash
Kraken2_genome_${dbs}
```

You may want to update these paths so they use the same directory name.

---

## Example command

```bash
sbatch Endo_hunt_BLAST.sh ERR647685
```

---

## Citation

If you use or modify this pipeline for your own cryptic species hunting, please cite the associated study or repository.

Suggested wording:

> This analysis used the Endosymbiont_Hunting pipeline for read-level screening, metagenomic assembly, contig classification, and genome-quality assessment of putative Mycetohabitans-associated bacterial genomes from fungal sequencing datasets.

---

## License

- GPL-3.0 license
