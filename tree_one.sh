#!/bin/bash
# Arbre de gène d'UN locus avec IQ-TREE. Appelé par 06_gene_trees.sbatch.
set -euo pipefail
aln="$1"
name=$(basename "$aln" .fasta)
pre="$D_GT/per_locus/$name"
[[ -s "$pre.treefile" ]] && exit 0
# ModelFinder (MFP) + 1000 bootstraps ultrarapides, 1 cœur par locus
"$IQTREE" -s "$aln" -st DNA -m MFP -B "$UFBOOT" -T 1 --prefix "$pre" --quiet -redo
# On ne garde que l'essentiel pour économiser de l'espace
rm -f "$pre".{ckp.gz,mldist,uniqueseq.phy,model.gz,splits.nex,contree,bionj}
