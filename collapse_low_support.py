#!/usr/bin/env python3
"""Effondre les branches internes mal soutenues des arbres de gènes.

Lit un fichier Newick (un arbre par ligne, supports UFBoot d'IQ-TREE comme
étiquettes de nœuds) et remplace par une polytomie toute branche dont le
support est < MIN_SUPPORT. Les longueurs de branches sont retirées
(ASTRAL n'utilise que la topologie).
"""
import argparse
from io import StringIO

from Bio import Phylo


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("inp")
    ap.add_argument("out")
    ap.add_argument("--min_support", type=float, default=10)
    a = ap.parse_args()

    n_trees = n_collapsed = 0
    with open(a.inp) as fin, open(a.out, "w") as fout:
        for line in fin:
            line = line.strip()
            if not line:
                continue
            t = Phylo.read(StringIO(line), "newick")
            weak = [c for c in t.get_nonterminals()
                    if c is not t.root and c.confidence is not None
                    and c.confidence < a.min_support]
            for c in weak:
                t.collapse(c)
            n_collapsed += len(weak)
            for c in t.find_clades():
                c.branch_length = None
                c.confidence = None
            s = StringIO()
            Phylo.write(t, s, "newick", plain=True)
            fout.write(s.getvalue().strip() + "\n")
            n_trees += 1
    print(f"{n_trees} arbres ; {n_collapsed} branches effondrées (support < {a.min_support})")


if __name__ == "__main__":
    main()
