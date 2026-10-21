#!/bin/bash
#SBATCH --job-name=m12_collect
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
# =====================================================================
#  ÉTAPE 12 — Copie des résultats finaux vers /project (sauvegardé)
#  Le dossier obtenu est petit : c'est lui qu'on met sur Google Drive.
# =====================================================================
set -uo pipefail
source "$PIPE/env.sh"
R="$RESULTS"; mkdir -p "$R"/{01_qc,02_recovery,03_alignments,04_gene_trees,05_species_trees,06_concordance,07_introgression}

cp "$D_QC"/*_fastp.json "$R/01_qc/" 2>/dev/null
python "$PIPE/scripts/summarize_fastp.py" "$D_QC" --out "$R/01_qc/fastp_summary.tsv" 2>/dev/null
cp "$D_HYB"/{hybpiper_stats.tsv,seq_lengths.tsv,*.png,paralog_report.tsv} "$R/02_recovery/" 2>/dev/null
cp "$D_LOCI/filter_report.tsv" "$R/02_recovery/" 2>/dev/null
tar -czf "$R/03_alignments/alignments_final.tar.gz" -C "$D_ALN" final 2>/dev/null
cp "$D_SP"/genetrees*.tre "$D_SP/genetrees_loci.txt" "$R/04_gene_trees/" 2>/dev/null
tar -czf "$R/04_gene_trees/iqtree_logs.tar.gz" -C "$D_GT" per_locus 2>/dev/null
cp "$D_SP"/{astral.tre,astral_rooted.tre,astral.log,concat.treefile,concat_rooted.tre,concat.iqtree,concat.best_scheme.nex} \
   "$R/05_species_trees/" 2>/dev/null
cp "$D_CF"/*.cf.tree* "$D_CF"/*.cf.stat* "$D_CF"/*_summary* "$R/06_concordance/" 2>/dev/null
cp "$D_DS"/* "$R/07_introgression/" 2>/dev/null
cp "$D_VCF/snps.stats.txt" "$R/07_introgression/" 2>/dev/null

# Versions des logiciels (pour la section Méthodes)
{
  echo "Pipeline Mindarus — $(date '+%F')"
  echo "fastp:     $(fastp --version 2>&1 | head -1)"
  echo "HybPiper:  $(hybpiper --version 2>&1 | head -1)"
  echo "MAFFT:     $(mafft --version 2>&1 | head -1)"
  echo "ClipKIT:   $(clipkit --version 2>&1 | head -1)"
  echo "IQ-TREE:   $("$IQTREE" --version 2>&1 | head -1)"
  echo "ASTRAL-IV: $(astral4 2>&1 | grep -im1 version)"
  echo "BWA:       $(bwa 2>&1 | grep -m1 Version)"
  echo "samtools:  $(samtools --version | head -1)"
  echo "bcftools:  $(bcftools --version | head -1)"
  echo "Dsuite:    $(Dsuite 2>&1 | grep -im1 -E 'version|Dsuite')"
  echo; echo "--- config.sh ---"; cat "$PIPE/config.sh"
} > "$R/VERSIONS_ET_PARAMETRES.txt"

du -sh "$R"
log "Résultats dans $R"
