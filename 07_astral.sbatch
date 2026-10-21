#!/bin/bash
#SBATCH --job-name=m07_astral
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=06:00:00
# =====================================================================
#  ÉTAPE 7 — Arbre d'espèces par coalescence (ASTRAL-IV)
#  Les branches des arbres de gènes mal soutenues (UFBoot < $COLLAPSE_BS)
#  sont effondrées avant ASTRAL (améliore la précision).
# =====================================================================
set -euo pipefail
source "$PIPE/env.sh"
mkdir -p "$D_SP"

log "Rassemblement des arbres de gènes"
: > "$D_SP/genetrees.tre"; : > "$D_SP/genetrees_loci.txt"
for t in "$D_GT"/per_locus/*.treefile; do
    cat "$t" >> "$D_SP/genetrees.tre"
    basename "$t" .treefile >> "$D_SP/genetrees_loci.txt"
done
log "$(wc -l < "$D_SP/genetrees.tre") arbres de gènes"

python "$PIPE/scripts/collapse_low_support.py" \
    "$D_SP/genetrees.tre" "$D_SP/genetrees_collapsed.tre" --min_support "$COLLAPSE_BS"

log "ASTRAL-IV"
astral4 -i "$D_SP/genetrees_collapsed.tre" -o "$D_SP/astral.tre" -t "$NCPU" \
    2> "$D_SP/astral.log"

python "$PIPE/scripts/root_and_rename.py" "$D_SP/astral.tre" "$D_SP/astral_rooted.tre" \
    --outgroup "$OUTGROUP" --names "$NAMES"
log "Terminé : $D_SP/astral.tre"
