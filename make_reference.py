#!/usr/bin/env python3
"""Construit une référence pour l'alignement des lectures : pour chaque locus
retenu, la séquence la plus longue parmi tous les échantillons (sans trous)."""
import argparse
from pathlib import Path

from Bio import SeqIO


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--src_dir", required=True)
    ap.add_argument("--keep_list", required=True, help="liste des FASTA de loci retenus")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    def base(name):  # "gene_supercontig" -> "gene"
        return name[:-len("_supercontig")] if name.endswith("_supercontig") else name

    keep = {base(Path(l.strip()).stem) for l in open(a.keep_list) if l.strip()}
    n = 0
    with open(a.out, "w") as fout:
        for f in sorted(Path(a.src_dir).iterdir()):
            locus = base(f.stem)
            if locus not in keep:
                continue
            best = None
            for r in SeqIO.parse(f, "fasta"):
                s = str(r.seq).replace("-", "").upper()
                if best is None or len(s) > len(best):
                    best = s
            if best:
                fout.write(f">{locus}\n")
                for i in range(0, len(best), 80):
                    fout.write(best[i:i + 80] + "\n")
                n += 1
    print(f"Référence : {n} loci -> {a.out}")


if __name__ == "__main__":
    main()
