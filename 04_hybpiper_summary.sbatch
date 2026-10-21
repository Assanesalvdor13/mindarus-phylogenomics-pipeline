#!/bin/bash
#SBATCH --job-name=m04_summary
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=03:00:00
# =====================================================================
#  ÉTAPE 4 — Bilan HybPiper, extraction et filtrage des loci
#  - statistiques de récupération + carte de chaleur
#  - détection des paralogues
#  - un FASTA par locus, puis filtrage (couverture taxonomique, longueur)
# =====================================================================
set -euo pipefail
source "$PIPE/env.sh"

if [[ "$TARGET_TYPE" == "dna" ]]; then TF=(-t_dna "$TARGETS"); else TF=(-t_aa "$TARGETS"); fi
cd "$D_HYB"

log "Statistiques de récupération"
hybpiper stats "${TF[@]}" gene "$WORK/namelist.txt"
hybpiper recovery_heatmap seq_lengths.tsv || log "carte de chaleur non produite (non bloquant)"

log "Détection des paralogues"
hybpiper paralog_retriever "$WORK/namelist.txt" "${TF[@]}" || log "paralog_retriever : avertissement (non bloquant)"

log "Extraction des séquences ($SEQ_TYPE)"
rm -rf "$D_LOCI/raw"; mkdir -p "$D_LOCI/raw"
hybpiper retrieve_sequences "$SEQ_TYPE" "${TF[@]}" \
    --sample_names "$WORK/namelist.txt" --fasta_dir "$D_LOCI/raw"

log "Filtrage des loci"
python "$PIPE/scripts/filter_loci.py" \
    --in_dir "$D_LOCI/raw" --out_dir "$D_LOCI/filtered" \
    --n_samples "$(wc -l < "$WORK/namelist.txt")" \
    --min_taxa_frac "$MIN_TAXA_FRAC" --min_seq_frac "$MIN_SEQ_FRAC" \
    --report "$D_LOCI/filter_report.tsv"

ls "$D_LOCI/filtered"/*.fasta > "$D_LOCI/loci_list.txt"
log "Loci retenus : $(wc -l < "$D_LOCI/loci_list.txt")"

# --- Référence pour l'appel de SNP (étapes 10-11) -----------------------
# Pour chaque locus retenu, on prend la séquence la plus longue
# (supercontig = exons + introns flanquants, plus de sites variables).
log "Construction de la référence pour les SNP"
rm -rf "$D_LOCI/supercontig"; mkdir -p "$D_LOCI/supercontig" "$D_VCF"
if hybpiper retrieve_sequences supercontig "${TF[@]}" \
       --sample_names "$WORK/namelist.txt" --fasta_dir "$D_LOCI/supercontig"; then
    SRC="$D_LOCI/supercontig"
else
    log "supercontigs indisponibles : on utilise les exons"; SRC="$D_LOCI/raw"
fi
python "$PIPE/scripts/make_reference.py" --src_dir "$SRC" \
    --keep_list "$D_LOCI/loci_list.txt" --out "$D_VCF/reference.fasta"
bwa index "$D_VCF/reference.fasta"
samtools faidx "$D_VCF/reference.fasta"
log "Référence : $(grep -c '>' "$D_VCF/reference.fasta") loci"
