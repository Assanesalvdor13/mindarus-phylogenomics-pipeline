#!/bin/bash
#SBATCH --job-name=m03_hybpiper
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
# =====================================================================
#  ÉTAPE 3 — Récupération des loci AHE (HybPiper assemble)
#  Une tâche par échantillon. Calcul sur le disque local du nœud
#  ($SLURM_TMPDIR, beaucoup plus rapide), puis copie vers /scratch.
# =====================================================================
set -euo pipefail
source "$PIPE/env.sh"

s=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES" | cut -f1)
mkdir -p "$D_HYB"
if [[ -f "$D_HYB/$s/genes_with_seqs.txt" ]]; then log "$s déjà assemblé, on passe."; exit 0; fi

if [[ "$TARGET_TYPE" == "dna" ]]; then
    TFLAG=(-t_dna "$TARGETS" --bwa)
else
    TFLAG=(-t_aa "$TARGETS" --diamond)
fi

cd "$TMPD"
log "HybPiper assemble : $s"
hybpiper assemble "${TFLAG[@]}" \
    -r "$D_QC/${s}_R1.fq.gz" "$D_QC/${s}_R2.fq.gz" \
    --unpaired "$D_QC/${s}_U.fq.gz" \
    --prefix "$s" --cpu "$NCPU"

log "Copie des résultats vers $D_HYB"
rm -rf "${D_HYB:?}/$s"
cp -r "$TMPD/$s" "$D_HYB/"
if [[ ! -s "$D_HYB/$s/genes_with_seqs.txt" ]]; then
    log "ÉCHEC : aucun locus récupéré pour $s (voir le journal ci-dessus)"; exit 1
fi
log "Terminé : $s ($(wc -l < "$D_HYB/$s/genes_with_seqs.txt") loci récupérés)"
