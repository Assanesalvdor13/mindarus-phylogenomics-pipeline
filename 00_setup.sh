#!/bin/bash
# =====================================================================
#  ÉTAPE 0 — Installation (une seule fois, sur le nœud de connexion)
#  Usage :  bash 00_setup.sh
#  Durée :  ~10-20 min. Rien de lourd n'est calculé ici.
# =====================================================================
set -uo pipefail
source "$(dirname "$0")/config.sh"
cd "$PIPE" || { echo "Dossier $PIPE introuvable : vérifiez PIPE dans config.sh"; exit 1; }

ok=0; bad=0
pass() { echo "  [OK]   $*"; ok=$((ok+1)); }
fail() { echo "  [MANQUE] $*"; bad=$((bad+1)); }

echo "=== 1. Modules du cluster ==="
module -q load StdEnv/2023
for m in python/3.11 scipy-stack fastp spades bwa samtools bcftools \
         exonerate diamond blast+ mafft iq-tree bbmap; do
    if module -q load "$m" 2>/dev/null; then pass "$m"; else fail "$m  (essayez : module spider ${m%%/*})"; fi
done

echo "=== 2. Environnement Python (~/venvs/mindarus) ==="
if [[ ! -d "$HOME/venvs/mindarus" ]]; then
    virtualenv --no-download "$HOME/venvs/mindarus" || python -m venv "$HOME/venvs/mindarus"
fi
source "$HOME/venvs/mindarus/bin/activate"
pip install --no-index --upgrade pip >/dev/null 2>&1
for p in biopython pandas matplotlib seaborn scipy psutil; do
    pip install --no-index "$p" >/dev/null 2>&1 || pip install "$p" >/dev/null 2>&1
done
for p in pebble progressbar2 clipkit; do
    pip install --no-index "$p" >/dev/null 2>&1 || pip install "$p" >/dev/null 2>&1
done
if ! command -v hybpiper >/dev/null 2>&1; then
    pip install "git+https://github.com/mossmatters/HybPiper.git" >/dev/null 2>&1
fi
# Correctif : la version de Biopython de l'Alliance ("1.86+computecanada")
# fait planter le test de version de HybPiper.
hp=$(python -c "import hybpiper,os;print(os.path.dirname(hybpiper.__file__))" 2>/dev/null)/hybpiper_main.py
[[ -f "$hp" ]] && sed -i "s/re.split('\\[\\.\\]', biopython_version_print)/re.split('[.+]', biopython_version_print)/" "$hp"
for c in hybpiper clipkit; do
    command -v "$c" >/dev/null 2>&1 && pass "$c" || fail "$c"
done
python -c "import Bio, pandas, matplotlib" 2>/dev/null && pass "biopython/pandas/matplotlib" || fail "biopython/pandas/matplotlib"

echo "=== 3. Outils compilés (ASTER, Dsuite) ==="
mkdir -p "$PIPE/tools"
if [[ ! -x "$PIPE/tools/ASTER/bin/astral4" ]]; then
    ( cd "$PIPE/tools" && rm -rf ASTER && git clone -q https://github.com/chaoszhang/ASTER.git \
      && cd ASTER && make >/dev/null 2>&1 )
fi
[[ -x "$PIPE/tools/ASTER/bin/astral4" ]] && pass "astral4 (ASTER)" || fail "astral4 (ASTER)"
if [[ ! -x "$PIPE/tools/Dsuite/Build/Dsuite" ]]; then
    ( cd "$PIPE/tools" && rm -rf Dsuite && git clone -q https://github.com/millanek/Dsuite.git \
      && cd Dsuite && make >/dev/null 2>&1 )
fi
[[ -x "$PIPE/tools/Dsuite/Build/Dsuite" ]] && pass "Dsuite" || fail "Dsuite"

echo "=== 4. Vérification complète via env.sh ==="
source "$PIPE/env.sh" 2>/dev/null
for c in fastp spades.py bwa samtools bcftools exonerate mafft parallel "$IQTREE"; do
    command -v "$c" >/dev/null 2>&1 && pass "$c" || fail "$c"
done
echo "--- hybpiper check_dependencies ---"
hybpiper check_dependencies 2>&1 | tail -n 20

echo "=== 5. Fichiers de référence ==="
[[ -s "$TARGETS" ]] && pass "cibles AHE : $TARGETS ($(grep -c '>' "$TARGETS") séquences)" \
                    || fail "cibles AHE absentes : copiez le fichier dans $TARGETS"
[[ -d "$RAW_DIR" ]] && pass "données brutes : $RAW_DIR ($(find "$RAW_DIR" -name "*$R1_SUFFIX" | wc -l) fichiers R1)" \
                    || fail "dossier de données brutes introuvable : $RAW_DIR"

echo
echo "Bilan : $ok OK, $bad manquant(s)."
[[ $bad -gt 0 ]] && echo "Copiez cette sortie à Claude pour corriger ce qui manque."
