#!/bin/bash
#SBATCH --job-name=m11b_clades
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=03:00:00
# ÉTAPE 11b — Dsuite au niveau des clades (tests des branches 35, 49, 51)
# Échantillons présents dans < MINLOCI alignements finaux => exclus (xxx)
set -euo pipefail
source "$PIPE/env.sh"
MINLOCI=${MINLOCI:-100}
OUT="$D_DS/clades"; mkdir -p "$OUT"; cd "$OUT"
vcf="$D_VCF/snps.filtered.vcf.gz"

grep -h '>' "$D_ALN"/final/*.fasta | sed 's/>//; s/[ \t].*//' | sort | uniq -c \
    | awk '{print $2"\t"$1}' > loci_par_echantillon.tsv
bcftools query -l "$vcf" > vcf_samples.txt

python - "$NAMES" "$SETS" loci_par_echantillon.tsv vcf_samples.txt "$MINLOCI" <<'PY'
import sys
names_f, sets_f, loci_f, vcf_f, minloci = sys.argv[1:]
N = dict(l.rstrip("\n").split("\t")[:2] for l in open(names_f) if "\t" in l)
OG = {l.split("\t")[0] for l in open(sets_f) if l.rstrip("\n").endswith("Outgroup")}
L = {a: int(b) for a, b in (l.split() for l in open(loci_f))}
rules = [("keteleerifoliae", "KET"), ("Liaoning", "EA_N"), ("japonicus", "EA_N"),
         ("Cangshan", "EA_S"), ("Shanxi", "EA_S"), ("Tibet", "EA_S"), ("Yunnan", "EA_S"),
         ("abietinus", "EU"), ("Lake_Tahoe", "NA1"), ("kinseyi", "NA1"), ("n_sp_Abies", "NA1"),
         ("n_sp_Picea", "NA1"), ("Coahuila", "NA2a"), ("concolor", "NA2a"), ("las_bif", "NA2a"),
         ("pinicola", "NA2a"), ("Nuevo_Leon", "NA2b"), ("remaudierei", "NA2b"), ("victoria", "NA2v")]
out, rep = open("sets_clades.txt", "w"), open("affectation.tsv", "w")
rep.write("echantillon\tnom\tloci\tgroupe\n")
for s in (l.strip() for l in open(vcf_f) if l.strip()):
    nom = N.get(s, s); n = L.get(s, 0)
    g = "Outgroup" if s in OG else next((c for k, c in rules if k in nom), None)
    if g is None and nom == "Mindarus_sp": g = "NA1"
    if g is None or (g != "Outgroup" and n < int(minloci)): g = "xxx"
    out.write(f"{s}\t{g}\n"); rep.write(f"{s}\t{nom}\t{n}\t{g}\n")
PY
column -t affectation.tsv

TREE=(); used=$(awk '$2!="xxx"{print $2}' sets_clades.txt | sort -u | paste -sd' ')
echo '(Outgroup,(KET,((EA_N,EA_S),(NA1,(EU,(NA2v,(NA2b,NA2a)))))));' > clades.nwk
ok=1; for g in Outgroup KET EA_N EA_S NA1 EU NA2v NA2b NA2a; do [[ " $used " == *" $g "* ]] || ok=0; done
[[ $ok == 1 ]] && TREE=(-t clades.nwk) || log "Un groupe est vide : pas d'arbre (Fbranch ignoré)"

log "Dsuite Dtrios (groupes : $used)"
Dsuite Dtrios --ABBAclustering -o clades "${TREE[@]}" "$vcf" sets_clades.txt \
  || Dsuite Dtrios -o clades "${TREE[@]}" "$vcf" sets_clades.txt
if [[ ${#TREE[@]} -gt 0 ]]; then
    Dsuite Fbranch clades.nwk clades_tree.txt > fbranch.txt || true
fi
python "$PIPE/scripts/summarize_dsuite.py" clades_BBAA.txt --out dsuite_clades_summary.tsv || true
log "Terminé : $OUT"
