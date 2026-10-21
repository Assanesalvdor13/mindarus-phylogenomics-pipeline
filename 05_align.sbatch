#!/bin/bash
#SBATCH --job-name=m05_align
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=04:00:00
# =====================================================================
#  ÉTAPE 5 — Alignement (MAFFT), élagage (ClipKIT), nettoyage
#  Les loci sont répartis en $N_CHUNKS tâches ; chaque tâche traite
#  ses loci en parallèle (un cœur par locus).
# =====================================================================
set -euo pipefail
source "$PIPE/env.sh"
mkdir -p "$D_ALN"/{raw,final,rejected}

awk -v n="$N_CHUNKS" -v t="$SLURM_ARRAY_TASK_ID" '(NR-1)%n==t-1' "$D_LOCI/loci_list.txt" \
    > "$TMPD/my_loci.txt"
log "Tâche $SLURM_ARRAY_TASK_ID : $(wc -l < "$TMPD/my_loci.txt") loci"
[[ -s "$TMPD/my_loci.txt" ]] || exit 0

parallel -j "$NCPU" --halt never bash "$PIPE/scripts/align_one.sh" {} :::: "$TMPD/my_loci.txt" || true
log "Terminé"
