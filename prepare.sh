#!/bin/bash
# =====================================================================
#  PRÉPARATION AUTOMATIQUE (une seule commande, sur le nœud de connexion)
#    1. télécharge les cibles BUSCO des hémiptères (protéines)
#    2. règle config.sh (cibles protéiques, données, outgroups)
#    3. crée sets.txt et names.tsv à partir de SequencingToDate.csv
#    4. soumet une tâche qui décompresse les données brutes dans /scratch
#  Usage :  bash prepare.sh
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./config.sh
ZIP="${DATA_ZIP:-/project/$ACCOUNT/$USER/mindarus_project/mindarus_data.zip}"
CSV="$HOME/mindarus_project/SequencingToDate.csv"
mkdir -p ref tmp "$WORK" "$LOGS"

echo "=== 1. Cibles BUSCO (hemiptera_odb10) ==="
if [[ ! -s ref/targets.fasta ]]; then
    url="https://busco-archive.ezlab.org/data/lineages/hemiptera_odb10/ancestral"
    curl -fsSL "$url" -o tmp/ancestral \
        || { echo "Téléchargement impossible ($url) : copiez cette sortie à Claude."; exit 1; }
    # Format HybPiper : >Source-NomDuGène
    awk '/^>/{split(substr($0,2),a," "); print ">hemiptera-"a[1]; next}{gsub(/[.*]/,"X"); print}' tmp/ancestral > ref/targets.fasta
    rm -rf tmp
fi
echo "  $(grep -c '>' ref/targets.fasta) gènes cibles -> ref/targets.fasta"

echo "=== 2. Échantillons, espèces et outgroups (SequencingToDate.csv) ==="
# Colonnes : ID ... Aphididae Genre Espèce(s) Date ...  -> échantillon P0062_CF_I<ID>
FS=$'\t'; grep -q $'\t' "$CSV" || FS=' '
awk -F"$FS" '{
    s="P0062_CF_I"$1; g=""; sp=""; gi=0;
    for(i=1;i<=NF;i++) if($i=="Aphididae" || $i=="Phylloxeridae" || $i=="Adelgidae"){gi=i; break}
    if(gi==0) next;
    g=$(gi+1);
    for(j=gi+2;j<=NF;j++){ if($j ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]/ || $j=="NULL" || $j=="") break; sp=(sp=="")?$j:sp" "$j }
    if(sp=="" || sp=="x") sp="sp";
    gsub(/[ .+]+/,"_",sp); gsub(/_+$/,"",sp);
    pop=(g=="Mindarus") ? "Mindarus_"sp : "Outgroup";
    print s"\t"pop > "ref/sets.txt";
    print s"\t"g"_"sp > "ref/names.tsv";
}' "$CSV"
OG=$(awk -F'\t' '$2=="Outgroup"{print $1}' ref/sets.txt | paste -sd,)
echo "  $(grep -vc Outgroup ref/sets.txt) Mindarus, $(grep -c Outgroup ref/sets.txt) outgroups"

sed -i 's|^export TARGET_TYPE=.*|export TARGET_TYPE="aa"|' config.sh
sed -i "s|^export RAW_DIR=.*|export RAW_DIR=\"$WORK/raw\"|" config.sh
sed -i "s|^export OUTGROUP=.*|export OUTGROUP=\"$OG\"|" config.sh
echo "  config.sh mis à jour (cibles protéiques, données dans \$WORK/raw)"

echo "=== 3. Décompression des données brutes (tâche SLURM, ~1-2 h) ==="
[[ -s "$ZIP" ]] || { echo "Zip introuvable : $ZIP"; exit 1; }
jid=$(sbatch --parsable --account="$ACCOUNT" --job-name=m01_unzip \
      --cpus-per-task=2 --mem=4G --time=06:00:00 --output="$LOGS/unzip_%j.out" \
      --wrap="mkdir -p $WORK/raw && cd $WORK/raw && unzip -q -n '$ZIP' && bash $PIPE/01_inventory.sh")
echo "  Tâche soumise : $jid"
echo
echo "C'est tout pour aujourd'hui. Vérifiez demain avec :  squeue -u $USER"
echo "Quand la tâche a disparu de la liste :           cat $LOGS/unzip_$jid.out"
