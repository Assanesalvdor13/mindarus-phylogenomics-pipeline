#!/bin/bash
# Charge les modules et l'environnement Python. Lu par chaque étape.
# (Créé une fois par 00_setup.sh ; rien à modifier ici normalement.)

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

module -q load StdEnv/2023 2>/dev/null
for m in python/3.11 scipy-stack fastp spades bwa samtools bcftools \
         exonerate diamond blast+ mafft iq-tree bbmap; do
    module -q load "$m" 2>/dev/null || echo "[env] module introuvable : $m" >&2
done

# Environnement Python (HybPiper, ClipKIT, Biopython)
if [[ -f "$HOME/venvs/mindarus/bin/activate" ]]; then
    source "$HOME/venvs/mindarus/bin/activate"
fi

# Outils compilés par 00_setup.sh
export TOOLS="$PIPE/tools"
export PATH="$TOOLS/ASTER/bin:$TOOLS/Dsuite/Build:$PATH"

# IQ-TREE : iqtree3 si présent, sinon iqtree2
if command -v iqtree3 >/dev/null 2>&1; then IQTREE=iqtree3; else IQTREE=iqtree2; fi
export IQTREE

# Répertoire temporaire local du nœud (rapide) ; sinon /tmp
export TMPD="${SLURM_TMPDIR:-/tmp/$USER}"
mkdir -p "$TMPD"

# Nombre de cœurs alloués
export NCPU="${SLURM_CPUS_PER_TASK:-1}"

log() { echo "[$(date '+%F %T')] $*"; }
