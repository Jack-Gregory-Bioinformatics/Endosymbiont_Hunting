# Endosymbiont_Hunting

## Overview

`Endo_hunt.sh` is an automated metagenomic analysis pipeline designed to
detect, assemble, and classify **Mycetohabitans-associated bacterial and fungal
genomes** from paired-end SRA sequencing data.

Given a single SRA Run ID, the pipeline performs read quality control, trimming,
taxonomic classification, conditional filtering, metagenomic assembly, contig
binning, genome quality assessment, fungal ITS extraction, and visualization.

The workflow is designed for **HPC environments** and supports batch execution
(e.g. via SLURM).

---

## Usage

```bash
./Endo_hunt.sh <Run_ID>
```

For batch submissions:
```bash
while read srr; do
  sbatch Endo_hunt_BLAST.sh "$srr"
done < input_srr_list.txt
```

---

Including:
- A yaml file for the creation of each conda environment used in the script
- Custom Kraken2 db build
- Main Endo-hunting script
