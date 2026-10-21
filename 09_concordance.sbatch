#!/bin/bash
#SBATCH --job-name=m09_concord
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
# ÉTAPE 9 — Concordance : gCF (arbres de gènes) puis sCF (sites), en deux passes
# (cette version d'IQ-TREE refuse --gcf et --scfl dans la même commande)
set -euo pipefail
source "$PIPE/env.sh"
mkdir -p "$D_CF"
for tree in astral concat; do
    case $tree in astral) t="$D_SP/astral.tre" ;; concat) t="$D_SP/concat.treefile" ;; esac
    [[ -s "$t" ]] || { log "Arbre $tree absent, ignoré"; continue; }
    log "gCF sur l'arbre $tree"
    "$IQTREE" -t "$t" --gcf "$D_SP/genetrees.tre" -T "$NCPU" --prefix "$D_CF/${tree}_gcf" -redo
    log "sCF sur l'arbre $tree"
    if [[ -s "$D_SP/concat.best_scheme.nex" ]]; then PART="$D_SP/concat.best_scheme.nex"; M=()
    else PART="$D_SP/aln_used"; M=(-m MFP); fi
    "$IQTREE" -te "$t" -p "$PART" "${M[@]}" -st DNA --scfl 100 -T "$NCPU" \
        --prefix "$D_CF/${tree}_scf" -redo || log "sCF non calculé pour $tree (non bloquant)"
    python "$PIPE/scripts/summarize_concordance.py" "$D_CF/${tree}_gcf.cf.stat" \
        --scf "$D_CF/${tree}_scf.cf.stat" --out_prefix "$D_CF/${tree}_summary"
done
log "Terminé"
