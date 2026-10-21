#!/usr/bin/env python3
"""Enracine un arbre sur l'outgroup et remplace les noms d'échantillons
par des noms lisibles (fichier TSV : échantillon<TAB>nom), pour les figures.
Les deux options sont facultatives : sans elles, l'arbre est recopié tel quel.
"""
import argparse
import os
import shutil

from Bio import Phylo


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("inp")
    ap.add_argument("out")
    ap.add_argument("--outgroup", default="", help="échantillon(s) séparés par des virgules")
    ap.add_argument("--names", default="", help="TSV échantillon<TAB>nom")
    a = ap.parse_args()

    try:
        t = Phylo.read(a.inp, "newick")
    except Exception as e:  # format inattendu : on ne bloque pas le pipeline
        print(f"Lecture impossible ({e}) ; copie sans modification.")
        shutil.copy(a.inp, a.out)
        return

    tips = {c.name for c in t.get_terminals()}
    og = [o.strip() for o in a.outgroup.split(",") if o.strip()]
    present = [o for o in og if o in tips]
    if og and not present:
        print(f"Outgroup {og} absent de l'arbre : pas d'enracinement.")
    elif present:
        t.root_with_outgroup(*present)
        t.ladderize()

    if a.names and os.path.isfile(a.names):
        mapping = {}
        with open(a.names) as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                if len(parts) >= 2 and parts[0]:
                    mapping[parts[0]] = parts[1].replace(" ", "_")
        for c in t.get_terminals():
            if c.name in mapping:
                c.name = f"{mapping[c.name]}|{c.name}"

    Phylo.write(t, a.out, "newick")
    print(f"Écrit : {a.out}")


if __name__ == "__main__":
    main()
