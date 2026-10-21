# Mindarus phylogenomics pipeline

A reproducible SLURM pipeline for target-capture phylogenomics, from raw
Illumina FASTQ files to a coalescent species tree, gene/site concordance
factors and introgression tests. Built for the Digital Research Alliance of
Canada clusters (tested on **Rorqual**) and applied to conifer-feeding aphids
of the genus *Mindarus* (Hemiptera: Aphididae).

*Version française résumée plus bas.*

## Workflow

```
 raw FASTQ
   │ 02  fastp ............ adapter/quality trimming            (array: 1 task / sample)
   │ 03  HybPiper ......... locus assembly (protein targets, DIAMOND) (array)
   │ 04  summary + filter . recovery stats, paralogs, per-locus FASTA, taxon-occupancy filter
   │ 05  MAFFT + ClipKIT .. alignment and trimming               (array: 40 chunks)
   │ 06  IQ-TREE .......... gene trees (ModelFinder + UFBoot)    (array: 40 chunks)
   ├─07  ASTRAL-IV ........ coalescent species tree (low-support branches collapsed)
   ├─08  IQ-TREE .......... partitioned concatenated tree (MFP+MERGE)
   │ 09  gCF / sCF ........ gene and site concordance factors + gDF asymmetry test
   │ 10  BWA .............. read mapping to a supercontig reference (array)
   │ 11  bcftools + Dsuite  SNP calling, Patterson's D, f4-ratio, f-branch
   │ 11b Dsuite (clades) .. clade-level tests, low-coverage samples excluded
   └ 12  collect .......... final results + software versions -> /project
```

Every step **skips work already done**, so any part can be rerun safely.
Steps are chained with SLURM dependencies (`afterok`).

## Key design choices

- **Targets without a lab probe set**: when the original AHE target file was
  unavailable, BUSCO `hemiptera_odb10` ancestral protein sequences (2,510 genes)
  were used as HybPiper targets (`-t_aa --diamond`).
- **Two species-tree methods** (ASTRAL-IV and concatenation) to separate
  topology signal from method artefacts.
- **Concordance factors** (gCF/sCF) and a χ² test on gDF1 vs gDF2 to
  distinguish incomplete lineage sorting (symmetric discordance) from possible
  introgression (asymmetric discordance).
- **Introgression tests at two levels** (per species, then per clade with
  `--ABBAclustering`), excluding samples recovered for < 100 loci to limit
  reference bias and missing-data artefacts.
- Robust batch execution: GNU parallel with `--halt never`, explicit failure
  checks (HybPiper can exit 0 on failure), compute nodes without internet.

## Usage

```bash
# 1. edit config.sh (ACCOUNT, RAW_DIR, OUTGROUP, ...)
bash 00_setup.sh            # modules, Python venv, HybPiper, ASTER, Dsuite
bash prepare.sh             # targets, sample/species tables, unzip raw data
bash 01_inventory.sh        # sample sheet from FASTQ names
bash run_pipeline.sh        # submit all steps with dependencies
bash run_pipeline.sh --from 9 --to 9     # rerun one step
bash run_pipeline.sh --dry-run           # show what would be submitted
```

Reference files in `ref/` (not distributed): `targets.fasta`, `sets.txt`
(sample → species / `Outgroup` / `xxx`), `names.tsv` (sample → readable name).

## Software

fastp · HybPiper 2 · DIAMOND · SPAdes · MAFFT (L-INS-i) · ClipKIT ·
IQ-TREE 2/3 · ASTRAL-IV (ASTER) · BWA · samtools · bcftools · Dsuite ·
Python (Biopython, pandas, matplotlib) · SLURM

## Data

Raw sequence data and results belong to the Favret laboratory (Université de
Montréal / IRBV) and are not included in this repository.

## Author

Assane Mbow — MSc Bioinformatics, Université de Montréal.
Research supervised by Prof. Colin Favret (IRBV).

---

## En bref (français)

Pipeline SLURM reproductible pour la phylogénomique par capture de cibles :
des FASTQ bruts à l'arbre d'espèces (ASTRAL-IV et concaténation), aux facteurs
de concordance (gCF/sCF) et aux tests d'introgression (Dsuite). Conçu pour les
grappes de l'Alliance de recherche numérique du Canada et appliqué aux
pucerons du genre *Mindarus*.

## License

MIT — see `LICENSE`.
