#!/usr/bin/env python3
"""Résume la sortie Dsuite (*_BBAA.txt) avec correction pour tests multiples
(Bonferroni et Benjamini-Hochberg), triée par Z-score."""
import argparse

import pandas as pd


def bh(p):
    n = len(p)
    order = p.sort_values().index
    ranked = p.loc[order] * n / pd.Series(range(1, n + 1), index=order)
    adj = ranked[::-1].cummin()[::-1].clip(upper=1)
    return adj.reindex(p.index)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("bbaa")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    df = pd.read_csv(a.bbaa, sep="\t")
    pcol = next(c for c in df.columns if c.lower().startswith("p-value"))
    df["p_bonferroni"] = (df[pcol] * len(df)).clip(upper=1)
    df["q_BH"] = bh(df[pcol])
    df["significatif_BH_0.05"] = df["q_BH"] < 0.05
    zcol = next((c for c in df.columns if c.lower().startswith("z")), None)
    if zcol:
        df = df.sort_values(zcol, ascending=False)
    df.to_csv(a.out, sep="\t", index=False)
    print(f"{len(df)} trios ; {int(df['significatif_BH_0.05'].sum())} significatifs après correction BH")


if __name__ == "__main__":
    main()
