#!/bin/bash
#SBATCH --job-name=m10_map
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=03:00:00
# =====================================================================
#  ÉTAPE 10 — Alignement des lectures sur la référence (pour les SNP)
#  Une tâche par échantillon : BWA-MEM, tri, retrait des doublons PCR.
# =====================================================================
set -euo pipefail
source "$PIPE/env.sh"
mkdir -p "$D_VCF/bam"

s=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES" | cut -f1)
bam="$D_VCF/bam/$s.bam"
[[ -s "$bam.bai" ]] && { log "$s déjà aligné"; exit 0; }

ref="$D_VCF/reference.fasta"
log "BWA-MEM : $s"
bwa mem -t "$NCPU" -R "@RG\tID:$s\tSM:$s\tPL:ILLUMINA" "$ref" \
    "$D_QC/${s}_R1.fq.gz" "$D_QC/${s}_R2.fq.gz" \
  | samtools fixmate -m -@ 2 - - \
  | samtools sort -@ 2 -T "$TMPD/$s" -o "$TMPD/$s.sorted.bam" -
samtools markdup -r -@ "$NCPU" "$TMPD/$s.sorted.bam" "$TMPD/$s.bam"
mv "$TMPD/$s.bam" "$bam"
samtools index "$bam"
samtools flagstat "$bam" > "$D_VCF/bam/$s.flagstat.txt"
log "Terminé : $s"
