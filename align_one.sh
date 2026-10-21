#!/bin/bash
# Aligne, élague et nettoie UN locus. Appelé par 05_align.sbatch.
# Usage : align_one.sh locus.fasta
set -euo pipefail
in="$1"
name=$(basename "$in" .fasta)
out="$D_ALN/final/$name.fasta"
[[ -s "$out" || -f "$D_ALN/rejected/$name" ]] && exit 0

work="$TMPD/$name"; mkdir -p "$work"
# MAFFT L-INS-i : le plus précis pour quelques dizaines de séquences
mafft --localpair --maxiterate 1000 --thread 1 --quiet "$in" > "$work/aln.fasta"
cp "$work/aln.fasta" "$D_ALN/raw/$name.fasta"
# ClipKIT (mode smart-gap) : retire les colonnes peu informatives
clipkit "$work/aln.fasta" -o "$work/trim.fasta" >/dev/null 2>&1
# Retire les séquences trop lacunaires ; rejette l'alignement s'il devient trop court
python "$PIPE/scripts/clean_alignment.py" "$work/trim.fasta" "$out" \
    --max_gap_frac "$MAX_GAP_FRAC" --min_len "$MIN_ALN_LEN" --min_seqs 4 \
    || touch "$D_ALN/rejected/$name"
rm -rf "$work"
