#!/bin/bash
#SBATCH --job-name=m06_genetrees
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=08:00:00
# =====================================================================
#  ÉTAPE 6 — Arbres de gènes (IQ-TREE, ModelFinder + UFBoot)
#  Même découpage que l'étape 5 : $N_CHUNKS tâches, loci en parallèle.
# =====================================================================
set -euo pipefail
source "$PIPE/env.sh"
mkdir -p "$D_GT/per_locus"

ls "$D_ALN/final"/*.fasta | awk -v n="$N_CHUNKS" -v t="$SLURM_ARRAY_TASK_ID" '(NR-1)%n==t-1' \
    > "$TMPD/my_aln.txt"
log "Tâche $SLURM_ARRAY_TASK_ID : $(wc -l < "$TMPD/my_aln.txt") alignements"
[[ -s "$TMPD/my_aln.txt" ]] || exit 0

parallel -j "$NCPU" --halt never bash "$PIPE/scripts/tree_one.sh" {} :::: "$TMPD/my_aln.txt" || true
log "Terminé"
