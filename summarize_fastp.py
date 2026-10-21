#!/usr/bin/env python3
"""Tableau récapitulatif des rapports fastp (*_fastp.json) : lectures avant
et après nettoyage, Q30, taux de duplication."""
import argparse
import json
from pathlib import Path


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("qc_dir")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    rows = ["sample\treads_before\treads_after\tpct_kept\tq30_after\tduplication"]
    for f in sorted(Path(a.qc_dir).glob("*_fastp.json")):
        d = json.load(open(f))
        b = d["summary"]["before_filtering"]["total_reads"]
        af = d["summary"]["after_filtering"]
        dup = d.get("duplication", {}).get("rate", float("nan"))
        rows.append(f"{f.name.replace('_fastp.json', '')}\t{b}\t{af['total_reads']}\t"
                    f"{100 * af['total_reads'] / b if b else 0:.1f}\t"
                    f"{100 * af['q30_rate']:.1f}\t{100 * dup:.1f}")
    Path(a.out).write_text("\n".join(rows) + "\n")
    print(f"{len(rows) - 1} échantillons -> {a.out}")


if __name__ == "__main__":
    main()
