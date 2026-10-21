#!/usr/bin/env python3
"""Filtre les loci récupérés par HybPiper.

Pour chaque locus (un FASTA par locus) :
  1. retire les séquences plus courtes que MIN_SEQ_FRAC x la longueur médiane ;
  2. garde le locus seulement s'il reste >= MIN_TAXA_FRAC x N échantillons.
Les noms de séquences sont réduits au nom d'échantillon (HybPiper ajoute
parfois une description après un espace).
"""
import argparse
import statistics
from pathlib import Path

from Bio import SeqIO


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--in_dir", required=True)
    ap.add_argument("--out_dir", required=True)
    ap.add_argument("--n_samples", type=int, required=True)
    ap.add_argument("--min_taxa_frac", type=float, default=0.5)
    ap.add_argument("--min_seq_frac", type=float, default=0.4)
    ap.add_argument("--report", required=True)
    a = ap.parse_args()

    out = Path(a.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("*.fasta"):
        old.unlink()
    min_taxa = max(4, int(round(a.min_taxa_frac * a.n_samples)))

    files = sorted(p for p in Path(a.in_dir).iterdir()
                   if p.suffix.lower() in {".fasta", ".fna", ".fa", ".faa"})
    kept = 0
    with open(a.report, "w") as rep:
        rep.write("locus\tn_input\tmedian_len\tn_after_length_filter\tkept\n")
        for f in files:
            recs = []
            for r in SeqIO.parse(f, "fasta"):
                r.id = r.id.split()[0]
                r.description = ""
                r.seq = r.seq.replace("-", "")
                if len(r.seq) > 0:
                    recs.append(r)
            if not recs:
                rep.write(f"{f.stem}\t0\t0\t0\tno\n")
                continue
            med = statistics.median(len(r.seq) for r in recs)
            good = [r for r in recs if len(r.seq) >= a.min_seq_frac * med]
            # un seul exemplaire par échantillon
            seen, uniq = set(), []
            for r in good:
                if r.id not in seen:
                    seen.add(r.id)
                    uniq.append(r)
            ok = len(uniq) >= min_taxa
            rep.write(f"{f.stem}\t{len(recs)}\t{med:.0f}\t{len(uniq)}\t{'yes' if ok else 'no'}\n")
            if ok:
                SeqIO.write(uniq, out / f"{f.stem}.fasta", "fasta")
                kept += 1
    print(f"{kept}/{len(files)} loci gardés (seuil : >= {min_taxa} échantillons)")


if __name__ == "__main__":
    main()
