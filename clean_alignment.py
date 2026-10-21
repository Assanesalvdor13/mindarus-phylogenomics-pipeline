#!/usr/bin/env python3
"""Nettoie un alignement élagué.

Retire les séquences avec plus de MAX_GAP_FRAC de trous/N, puis les
colonnes devenues entièrement vides. Sort avec le code 1 (alignement
rejeté) s'il reste moins de MIN_SEQS séquences ou moins de MIN_LEN sites.
"""
import argparse
import sys

from Bio import SeqIO
from Bio.Seq import Seq

GAPS = set("-?NnXx")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("inp")
    ap.add_argument("out")
    ap.add_argument("--max_gap_frac", type=float, default=0.5)
    ap.add_argument("--min_len", type=int, default=100)
    ap.add_argument("--min_seqs", type=int, default=4)
    a = ap.parse_args()

    recs = list(SeqIO.parse(a.inp, "fasta"))
    if not recs:
        sys.exit(1)
    L = len(recs[0].seq)
    keep = [r for r in recs
            if L and sum(c in GAPS for c in str(r.seq)) / L <= a.max_gap_frac]
    if len(keep) < a.min_seqs:
        sys.exit(1)
    cols = [i for i in range(L) if any(str(r.seq)[i] not in GAPS for r in keep)]
    for r in keep:
        s = str(r.seq)
        r.seq = Seq("".join(s[i] for i in cols))
        r.description = ""
    if len(cols) < a.min_len:
        sys.exit(1)
    SeqIO.write(keep, a.out, "fasta")


if __name__ == "__main__":
    main()
