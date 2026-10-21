#!/usr/bin/env python3
"""Résume gCF + sCF d'IQ-TREE (voir README)."""
import argparse
import math

import pandas as pd


def chi2_p(a, b):
    n = a + b
    if n == 0:
        return float("nan")
    x = (a - b) ** 2 / n
    return math.erfc(math.sqrt(x / 2))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("cf_stat")
    ap.add_argument("--scf", default="", help="fichier .cf.stat du sCF (calcul séparé)")
    ap.add_argument("--out_prefix", required=True)
    a = ap.parse_args()

    def load(path):
        d = pd.read_csv(path, sep="\t", comment="#")
        d.columns = [c.strip() for c in d.columns]
        return d

    df = load(a.cf_stat)
    if a.scf:
        try:
            s = load(a.scf)
            keep = ["ID"] + [c for c in s.columns if c.startswith("s")]
            df = df.merge(s[keep], on="ID", how="left")
        except (FileNotFoundError, KeyError) as e:
            print(f"sCF ignoré ({e})")
    if {"gDF1_N", "gDF2_N"} <= set(df.columns):
        df["gDF_asym_p"] = [chi2_p(x, y) for x, y in zip(df["gDF1_N"], df["gDF2_N"])]
        df["interpretation"] = [
            "asymetrie (introgression ?)" if p < 0.05 else "symetrique (compatible ILS)"
            for p in df["gDF_asym_p"]
        ]
    df.to_csv(f"{a.out_prefix}.tsv", sep="\t", index=False)

    scf = "sCF" if "sCF" in df.columns else next((c for c in df.columns if c.startswith("sCF")), None)
    if scf and "gCF" in df.columns:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        fig, ax = plt.subplots(figsize=(5, 5))
        ax.scatter(df["gCF"], df[scf], s=18, alpha=0.8)
        ax.plot([0, 100], [0, 100], lw=0.8, ls="--", color="grey")
        ax.axhline(33.3, lw=0.6, color="grey", ls=":")
        ax.set_xlim(0, 100); ax.set_ylim(0, 100)
        ax.set_xlabel("gCF (%)"); ax.set_ylabel(f"{scf} (%)")
        ax.set_title("Concordance par branche")
        fig.tight_layout()
        fig.savefig(f"{a.out_prefix}.png", dpi=200)

    low = df[df["gCF"] < 33.3] if "gCF" in df.columns else df.iloc[0:0]
    print(f"{len(df)} branches ; {len(low)} avec gCF < 33 %")


if __name__ == "__main__":
    main()
