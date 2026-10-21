#!/bin/bash
# =====================================================================
#  Lance tout le pipeline en une commande, avec les dépendances SLURM.
#
#  Usage :
#    bash run_pipeline.sh                # étapes 2 à 12
#    bash run_pipeline.sh --from 5       # reprendre à l'étape 5
#    bash run_pipeline.sh --from 2 --to 4   # seulement les étapes 2 à 4
#    bash run_pipeline.sh --dry-run      # afficher sans soumettre
#
#  Chaque étape saute ce qui est déjà fait : relancer est sans danger.
# =====================================================================
set -euo pipefail
source "$(dirname "$0")/config.sh"

FROM=2; TO=12; DRY=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --from) FROM=$2; shift 2 ;;
        --to)   TO=$2;   shift 2 ;;
        --dry-run) DRY=1; shift ;;
        *) echo "Option inconnue : $1"; exit 1 ;;
    esac
done

[[ -s "$SAMPLES" ]] || { echo "Lancez d'abord : bash 01_inventory.sh"; exit 1; }
[[ -s "$TARGETS" ]] || { echo "Fichier de cibles absent : $TARGETS"; exit 1; }
N=$(wc -l < "$SAMPLES")
mkdir -p "$LOGS"

declare -A JOB
# submit ÉTAPE SCRIPT ARRAY DÉPENDANCES...
submit() {
    local step=$1 script=$2 array=$3; shift 3
    if (( step < FROM || step > TO )); then return; fi
    local dep=() ids=() d
    for d in "$@"; do [[ -n "${JOB[$d]:-}" ]] && ids+=("${JOB[$d]}"); done
    (( ${#ids[@]} )) && dep=(--dependency="${DEPTYPE:-afterok}:$(IFS=:; echo "${ids[*]}")")
    local arr=(); [[ -n "$array" ]] && arr=(--array="$array")
    local cmd=(sbatch --parsable --account="$ACCOUNT" --export=ALL,PIPE="$PIPE"
               --output="$LOGS/%x_%A_%a.out" "${arr[@]}" "${dep[@]}" "$PIPE/$script")
    if (( DRY )); then
        echo "[dry-run] étape $step : ${cmd[*]}"; JOB[$step]="DRY$step"
    else
        JOB[$step]=$("${cmd[@]}")
        echo "Étape $step soumise : job ${JOB[$step]}  ($script)"
    fi
}

submit 2  02_fastp.sbatch            "1-$N"
submit 3  03_hybpiper.sbatch         "1-$N"         2
submit 4  04_hybpiper_summary.sbatch ""             3
submit 5  05_align.sbatch            "1-$N_CHUNKS"  4
submit 6  06_gene_trees.sbatch       "1-$N_CHUNKS"  5
submit 7  07_astral.sbatch           ""             6
submit 8  08_concat.sbatch           ""             6
submit 9  09_concordance.sbatch      ""             7 8
submit 10 10_map_reads.sbatch        "1-$N"         4
submit 11 11_snps_dsuite.sbatch      ""             10
# afterany : on rassemble les résultats même si Dsuite attend sets.txt
DEPTYPE=afterany submit 12 12_collect.sbatch "" 9 11

echo
echo "Suivi :  squeue -u $USER      Journaux : $LOGS"
