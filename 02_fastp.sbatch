#!/bin/bash
#SBATCH --job-name=m02_fastp
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
# =====================================================================
#  ÉTAPE 2 — Nettoyage et contrôle qualité des lectures (fastp)
#  Une tâche par échantillon (tableau SLURM). Fusionne les lanes,
#  retire adaptateurs et bases de mauvaise qualité.
# =====================================================================
set -euo pipefail
source "$PIPE/env.sh"

line=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")
s=$(cut -f1 <<<"$line"); r1s=$(cut -f2 <<<"$line"); r2s=$(cut -f3 <<<"$line")
out="$D_QC/$s"; mkdir -p "$D_QC"

if [[ -s "${out}_R1.fq.gz" && -s "${out}_R2.fq.gz" ]]; then
    log "$s déjà traité, on passe."; exit 0
fi

log "Échantillon $s : fusion des lanes"
# Des fichiers gzip concaténés restent un gzip valide
tr ',' '\n' <<<"$r1s" | xargs cat > "$TMPD/${s}_R1.fq.gz"
tr ',' '\n' <<<"$r2s" | xargs cat > "$TMPD/${s}_R2.fq.gz"

log "fastp"
fastp -i "$TMPD/${s}_R1.fq.gz" -I "$TMPD/${s}_R2.fq.gz" \
      -o "$TMPD/o_R1.fq.gz" -O "$TMPD/o_R2.fq.gz" \
      --unpaired1 "$TMPD/u1.fq.gz" --unpaired2 "$TMPD/u2.fq.gz" \
      --detect_adapter_for_pe --trim_poly_g \
      --cut_right --cut_right_window_size 4 --cut_right_mean_quality 20 \
      --qualified_quality_phred 20 --length_required 50 \
      --thread "$NCPU" \
      --html "${out}_fastp.html" --json "${out}_fastp.json" \
      --report_title "$s"

cat "$TMPD/u1.fq.gz" "$TMPD/u2.fq.gz" > "$TMPD/o_U.fq.gz"
mv "$TMPD/o_R1.fq.gz" "${out}_R1.fq.gz"
mv "$TMPD/o_R2.fq.gz" "${out}_R2.fq.gz"
mv "$TMPD/o_U.fq.gz"  "${out}_U.fq.gz"
log "Terminé : $s"
