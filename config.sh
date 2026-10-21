#!/bin/bash
# =====================================================================
#  Pipeline phylogénomique Mindarus — CONFIGURATION
#  Modifiez seulement ce fichier. Tous les autres scripts le lisent.
# =====================================================================

# --- Compte de calcul (allocation SLURM) --------------------
export ACCOUNT="def-yourpi"      # your SLURM allocation

# --- Emplacements ----------------------------------------------------
export USER="${USER:-$(whoami)}"
# Dossier de ce pipeline : détecté automatiquement (là où se trouve ce fichier)
PIPE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; export PIPE

# Données brutes : dossier contenant les .fastq.gz (sous-dossiers acceptés)
export RAW_DIR="$HOME/mindarus_project/raw_data"

# Espace de travail : /scratch est rapide et grand, MAIS les fichiers non
# utilisés depuis 60 jours y sont effacés. Les résultats finaux sont donc
# recopiés dans RESULTS à la fin.
export WORK="/scratch/$USER/mindarus_run"

# Résultats finaux (espace /project, sauvegardé chaque jour)
export RESULTS="/project/$ACCOUNT/$USER/mindarus_results"

# --- Fichiers de référence (à fournir dans $PIPE/ref/) ---------------
# Séquences cibles des loci AHE (une séquence par locus, format HybPiper :
#   >NomEchantillonRef-NomLocus ). OBLIGATOIRE.
export TARGETS="$PIPE/ref/targets.fasta"
export TARGET_TYPE="aa"          # "dna" (nucléotides) ou "aa" (protéines)

# Correspondance échantillon -> espèce pour Dsuite (créée par 01_inventory.sh,
# à compléter à la main). L'outgroup doit porter le mot-clé "Outgroup".
export SETS="$PIPE/ref/sets.txt"

# (Optionnel) noms lisibles pour les figures : échantillon<TAB>nom
export NAMES="$PIPE/ref/names.tsv"

# Échantillon(s) externe(s) pour enraciner les arbres (séparés par virgules)
export OUTGROUP=""

# --- Reconnaissance des fichiers FASTQ -------------------------------
export R1_SUFFIX="_R1_001.fastq.gz"
export R2_SUFFIX="_R2_001.fastq.gz"

# --- Paramètres d'analyse --------------------------------------------
export SEQ_TYPE="dna"             # séquences récupérées : "dna" (exons) ou "supercontig"
export MIN_TAXA_FRAC=0.50         # garder un locus présent chez >= 50 % des échantillons
export MIN_SEQ_FRAC=0.40          # retirer une séquence < 40 % de la longueur médiane du locus
export MAX_GAP_FRAC=0.50          # après alignement, retirer une séquence avec > 50 % de trous
export MIN_ALN_LEN=100            # longueur minimale d'un alignement (pb)
export UFBOOT=1000                # réplicats bootstrap ultrarapide (IQ-TREE)
export COLLAPSE_BS=10             # effondrer les branches des arbres de gènes avec UFBoot < 10
export N_CHUNKS=40                # nombre de tâches parallèles pour les loci

# --- Introgression (Dsuite) ------------------------------------------
export MIN_QUAL=30                # qualité minimale d'un SNP
export MIN_DP=5                   # profondeur minimale par génotype

# --- Dossiers dérivés (ne pas modifier) ------------------------------
export SAMPLES="$WORK/samples.tsv"
export D_QC="$WORK/01_fastp"
export D_HYB="$WORK/02_hybpiper"
export D_LOCI="$WORK/03_loci"
export D_ALN="$WORK/04_alignments"
export D_GT="$WORK/05_gene_trees"
export D_SP="$WORK/06_species_tree"
export D_CF="$WORK/07_concordance"
export D_VCF="$WORK/08_snps"
export D_DS="$WORK/09_dsuite"
export LOGS="$WORK/logs"
