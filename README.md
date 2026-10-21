# ref/ — reference files (not distributed)

| File | Required | Content |
|---|---|---|
| `targets.fasta` | yes | HybPiper targets (`>Source-LocusName`); BUSCO ancestral proteins with `TARGET_TYPE="aa"` |
| `sets.txt` | for Dsuite | `sample<TAB>species`, `Outgroup` for outgroups, `xxx` to ignore |
| `names.tsv` | optional | `sample<TAB>readable name` for figures |
| `species_tree.nwk` | optional | species-level tree (names as in `sets.txt`) for f-branch |
