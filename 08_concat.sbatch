#!/bin/bash
#SBATCH --job-name=m08_concat
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=48:00:00
# =====================================================================
#  ÉTAPE 8 — Arbre par concaténation (IQ-TREE, partitions par locus)
#  Approche complémentaire à ASTRAL ; sert aussi au calcul du sCF.
# =====================================================================
set -euo pipefail
source "$PIPE/env.sh"
mkdir -p "$D_SP"

# Seuls les loci qui ont un arbre de gène sont gardés (mêmes données qu'ASTRAL)
rm -rf "$D_SP/aln_used"; mkdir -p "$D_SP/aln_used"
for t in "$D_GT"/per_locus/*.treefile; do
    n=$(basename "$t" .treefile)
    ln -s "$D_ALN/final/$n.fasta" "$D_SP/aln_used/$n.fasta"
done

OG=()  # enracinement fait après, par root_and_rename.py
log "IQ-TREE concaténé ($(ls "$D_SP/aln_used" | wc -l) partitions)"
"$IQTREE" -p "$D_SP/aln_used" -st DNA -m MFP+MERGE --rclusterf 10 -B "$UFBOOT" \
    -T AUTO --threads-max "$NCPU" --prefix "$D_SP/concat" "${OG[@]}"

python "$PIPE/scripts/root_and_rename.py" "$D_SP/concat.treefile" "$D_SP/concat_rooted.tre" \
    --outgroup "$OUTGROUP" --names "$NAMES"
log "Terminé : $D_SP/concat.treefile"
