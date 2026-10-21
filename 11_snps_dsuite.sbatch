#!/bin/bash
#SBATCH --job-name=m11_dsuite
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=24:00:00
# =====================================================================
#  ÉTAPE 11 — Appel des SNP (bcftools) et tests d'introgression (Dsuite)
#  D de Patterson (ABBA-BABA) et f4-ratio pour tous les trios d'espèces.
#  Nécessite ref/sets.txt complété (échantillon -> espèce, + Outgroup).
#  Optionnel : ref/species_tree.nwk (arbre au niveau espèces, noms = sets.txt)
#  pour f-branch.
# =====================================================================
set -euo pipefail
source "$PIPE/env.sh"
mkdir -p "$D_DS"
ref="$D_VCF/reference.fasta"
vcf="$D_VCF/snps.filtered.vcf.gz"

if [[ ! -s "$vcf" ]]; then
    ls "$D_VCF"/bam/*.bam > "$D_VCF/bamlist.txt"
    log "Appel des variants ($(wc -l < "$D_VCF/bamlist.txt") échantillons)"
    bcftools mpileup --threads "$NCPU" -f "$ref" -b "$D_VCF/bamlist.txt" \
        -a FORMAT/AD,FORMAT/DP -q 20 -Q 20 -d 1000 -Ou \
      | bcftools call --threads "$NCPU" -mv -Oz -o "$D_VCF/snps.raw.vcf.gz"
    bcftools index "$D_VCF/snps.raw.vcf.gz"

    log "Filtrage : SNP bialléliques, QUAL>=$MIN_QUAL, génotypes DP<$MIN_DP -> manquants"
    bcftools view -m2 -M2 -v snps -i "QUAL>=$MIN_QUAL" "$D_VCF/snps.raw.vcf.gz" -Ou \
      | bcftools +setGT -Ou -- -t q -n . -i "FMT/DP<$MIN_DP" \
      | bcftools view -i 'F_MISSING<0.5' -Oz -o "$vcf"
    bcftools index "$vcf"
    bcftools stats "$vcf" > "$D_VCF/snps.stats.txt"
fi
log "SNP retenus : $(bcftools view -H "$vcf" | wc -l)"

if grep -q "A_COMPLETER" "$SETS" || ! grep -qw "Outgroup" "$SETS"; then
    log "ARRÊT : complétez $SETS (espèces + 'Outgroup') puis relancez seulement cette étape :"
    log "        sbatch --account=$ACCOUNT --export=ALL,PIPE=$PIPE $PIPE/11_snps_dsuite.sbatch"
    exit 1
fi

cd "$D_DS"
TREE=(); SPTREE="$PIPE/ref/species_tree.nwk"
[[ -s "$SPTREE" ]] && TREE=(-t "$SPTREE")
log "Dsuite Dtrios"
Dsuite Dtrios -o mindarus "${TREE[@]}" "$vcf" "$SETS"

if [[ -s "$SPTREE" ]]; then
    log "f-branch"
    Dsuite Fbranch "$SPTREE" mindarus_tree.txt > fbranch.txt
    python "$TOOLS/Dsuite/utils/dtools.py" fbranch.txt "$SPTREE" --outgroup Outgroup \
        || log "graphique f-branch non produit (non bloquant)"
fi
python "$PIPE/scripts/summarize_dsuite.py" "$D_DS/mindarus_BBAA.txt" --out "$D_DS/dsuite_summary.tsv"
log "Terminé"
