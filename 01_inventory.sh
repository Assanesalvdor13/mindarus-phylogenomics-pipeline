#!/bin/bash
# =====================================================================
#  ÉTAPE 1 — Inventaire des échantillons (nœud de connexion, quelques s)
#  Repère les FASTQ, regroupe les lignes de séquençage (L001, L002...)
#  par échantillon et écrit $WORK/samples.tsv.
#  Usage :  bash 01_inventory.sh
# =====================================================================
set -euo pipefail
source "$(dirname "$0")/config.sh"
mkdir -p "$WORK" "$LOGS" "$PIPE/ref"

# Nom d'échantillon = nom de fichier sans lane/R1/barcode.
#   P0062_CF_I9089_GTAATTAT_L002_R1_001.fastq.gz  ->  P0062_CF_I9089
sample_of() {
    basename "$1" \
    | sed -E "s/${R1_SUFFIX//./\\.}\$//; s/${R2_SUFFIX//./\\.}\$//" \
    | sed -E 's/_L[0-9]{3}$//; s/_S[0-9]+$//; s/_[ACGTN]{6,}(-[ACGTN]{6,})?$//'
}

tmp=$(mktemp)
find -L "$RAW_DIR" -type f -name "*${R1_SUFFIX}" | sort | while read -r r1; do
    r2="${r1%"$R1_SUFFIX"}$R2_SUFFIX"
    if [[ ! -f "$r2" ]]; then echo "ATTENTION : R2 manquant pour $r1" >&2; continue; fi
    printf '%s\t%s\t%s\n' "$(sample_of "$r1")" "$r1" "$r2"
done > "$tmp"

# Regroupe les lanes : une ligne par échantillon, fichiers séparés par des virgules
awk -F'\t' '{r1[$1]=(r1[$1]?r1[$1]",":"")$2; r2[$1]=(r2[$1]?r2[$1]",":"")$3}
            END{for(s in r1) print s"\t"r1[s]"\t"r2[s]}' "$tmp" | sort > "$SAMPLES"
rm -f "$tmp"

n=$(wc -l < "$SAMPLES")
echo "Échantillons trouvés : $n   ->  $SAMPLES"
awk -F'\t' '{n=split($2,a,","); printf "  %-25s %d lane(s)\n", $1, n}' "$SAMPLES" | head -n 70
cut -f1 "$SAMPLES" > "$WORK/namelist.txt"

# Modèle de fichier d'espèces pour Dsuite (à compléter)
if [[ ! -f "$SETS" ]]; then
    awk -F'\t' '{print $1"\tA_COMPLETER"}' "$SAMPLES" > "$SETS"
    echo
    echo "Modèle créé : $SETS"
    echo "  -> Remplacez A_COMPLETER par le nom d'espèce de chaque échantillon,"
    echo "     'Outgroup' pour l'outgroup, 'xxx' pour ignorer un échantillon."
    echo "     (SequencingToDate.csv peut vous aider.)"
fi
[[ "$n" -eq 0 ]] && { echo "Aucun FASTQ trouvé : vérifiez RAW_DIR et R1_SUFFIX dans config.sh"; exit 1; }
exit 0
