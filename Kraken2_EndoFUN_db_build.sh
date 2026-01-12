#!/bin/bash

conda activate Kraken2Krona
mkdir EndoFUN
cd EndoFUN

echo "Downloading Taxonomy"
kraken2-build --db EndoFUN_v1.7 --download-taxonomy
echo "Downloading Archaea"
kraken2-build --db EndoFUN_v1.7 --download-library archaea
echo "Downloading Bacteria"
kraken2-build --db EndoFUN_v1.7 --download-library bacteria
echo "Downloading Fungi"
kraken2-build --db EndoFUN_v1.7 --download-library fungi
echo "Downloading Viral"
kraken2-build --db EndoFUN_v1.7 --download-library viral
echo "Downloading UniVec Core"
kraken2-build --db EndoFUN_v1.7 --download-library UniVec_Core

echo "Adding mucorales and pathogenic fungi genomes to library"
kraken2-build --add-to-library PATHTO/L_corymbifera/ncbi_dataset/data/GCA_000697475.1/GCA_000697475.1_LicCorB2541-1.0_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/L_ramosa/ncbi_dataset/data/GCA_008728235.1/GCA_008728235.1_ASM872823v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_circinelloides/ncbi_dataset/data/GCA_001599575.1/GCA_001599575.1_JCM_22480_assembly_v001_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_racemosus/ncbi_dataset/data/GCA_027405735.1/GCA_027405735.1_ASM2740573v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_velutinosus/ncbi_dataset/data/GCA_000696895.1/GCA_000696895.1_MucVelB5328-1.0_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/R_arrhizus/ncbi_dataset/data/GCA_024220505.1/GCA_024220505.1_ASM2422050v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/Rhizopus_RO3G/GCA_000149305.1_RO3_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/RM_miehei/ncbi_dataset/data/GCA_000611695.1/GCA_000611695.1_RhzM_1.0_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/RM_pusillus/ncbi_dataset/data/GCA_900175165.2/GCA_900175165.2_FCH_5_7_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/A_trapeziformis/ncbi_dataset/data/GCA_000696975.1/GCA_000696975.1_ApoTraB9324-1.0_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/C_parapsilosis/ncbi_dataset/data/GCF_000182765.1/GCF_000182765.1_ASM18276v2_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/R_microsporus/ncbi_dataset/data/GCF_002708625.1/GCF_002708625.1_Rhimi1_1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/R_microsporus_ATCC_52814/ncbi_dataset/data/GCA_002083745.1/GCA_002083745.1_Rhimi_ATCC52814_1_genomic.fna --db EndoFUN_v1.7

kraken2-build --add-to-library PATHTO/A_elegans_B7760/ncbi_dataset/data/GCA_000696995.1/GCA_000696995.1_ApoEleB7760-1.0_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/A_ossiformis_NRRL_A-21654/ncbi_dataset/data/GCA_014839865.1/GCA_014839865.1_ASM1483986v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/A_variabilis_NCCPR_102052/ncbi_dataset/data/GCA_002749535.1/GCA_002749535.1_ASM274953v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/AM_elegans_CJ-6/ncbi_dataset/data/GCA_026027325.1/GCA_026027325.1_ASM2602732v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/C_bertholletiae_Z2/ncbi_dataset/data/GCA_037043795.1/GCA_037043795.1_Z2.assembly_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/C_elegans_B9769/ncbi_dataset/data/GCA_000697015.1/GCA_000697015.1_CunEleB9769-1.0_genomic.fna --db EndoFUN_v1.7

kraken2-build --add-to-library PATHTO/C_metapsilosis_BP57/ncbi_dataset/data/GCA_017655625.1/GCA_017655625.1_BP57_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_canis_CBS_113480/ncbi_dataset/data/GCA_000151145.1/GCA_000151145.1_ASM15114v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_dermatis_JCM_11348/ncbi_dataset/data/GCA_001600775.1/GCA_001600775.1_JCM_11348_assembly_v001_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_furfur_CBS_14141/ncbi_dataset/data/GCA_009938135.1/GCA_009938135.1_ASM993813v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_indicus_B7402/ncbi_dataset/data/GCA_000697295.1/GCA_000697295.1_MucIndB7402-1.0_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_irregularis_B50/ncbi_dataset/data/GCA_000587855.1/GCA_000587855.1_B50_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_lustitanicus_MU402/ncbi_dataset/data/GCA_010203745.1/GCA_010203745.1_Muccir1_3_genomic.fna --db EndoFUN_v1.7

kraken2-build --add-to-library PATHTO/R_stolonifer_B9770/ncbi_dataset/data/GCA_000697035.1/GCA_000697035.1_RhiStoB9770-1.0_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/S_monosporum_B8922/ncbi_dataset/data/GCA_000697355.1/GCA_000697355.1_SynMonB8922-1.0_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/S_racemosum_NRRL_2496/ncbi_dataset/data/GCA_002105135.1/GCA_002105135.1_Synrac1_genomic.fna --db EndoFUN_v1.7

kraken2-build --add-to-library PATHTO/T_putrescentiae_YC2013/ncbi_dataset/data/GCA_024499935.1/GCA_024499935.1_ASM2449993v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/C_umbellata_NRRL1351/ncbi_dataset/data/GCA_025093555.1/GCA_025093555.1_Cirumb1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/S_vasiformis_B4078/ncbi_dataset/data/GCA_000697055.1/GCA_000697055.1_SakVasB4078-1.0_genomic.fna --db EndoFUN_v1.7

kraken2-build --add-to-library PATHTO/M_endofungorum_B3/ncbi_dataset/data/GCF_037478085.1/GCF_037478085.1_ASM3747808v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_endofungorum_B5/ncbi_dataset/data/GCF_037478075.1/GCF_037478075.1_ASM3747807v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_endofungorum_B13/ncbi_dataset/data/GCF_037477895.1/GCF_037477895.1_ASM3747789v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_endofungorum_B14/ncbi_dataset/data/GCF_037477905.1/GCF_037477905.1_ASM3747790v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_endofungorum_B60/ncbi_dataset/data/GCF_037478035.1/GCF_037478035.1_ASM3747803v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_rhizoxinica_B12/ncbi_dataset/data/GCF_037478065.1/GCF_037478065.1_ASM3747806v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_rhizoxinica_B47/ncbi_dataset/data/GCF_037478055.1/GCF_037478055.1_ASM3747805v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_rhizoxinica_B49/ncbi_dataset/data/GCF_037478045.1/GCF_037478045.1_ASM3747804v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/M_rhizoxinica_HKI_454/ncbi_dataset/data/GCF_000198775.1/GCF_000198775.1_ASM19877v1_genomic.fna --db EndoFUN_v1.7

kraken2-build --add-to-library PATHTO/N_circulans/ncbi_dataset/data/GCF_013267435.1/GCF_013267435.1_ASM1326743v1_genomic.fna --db EndoFUN_v1.7
kraken2-build --add-to-library PATHTO/GCF_000001635.27_dataset/ncbi_dataset/data/GCF_000001635.27/GCF_000001635.27_GRCm39_genomic.fna --db EndoFUN_v1.7


echo "Building database"
kraken2-build --db EndoFUN_v1.7 --build --threads 32

echo "Complete, EndoFUN Kraken2 db has been built :)"
