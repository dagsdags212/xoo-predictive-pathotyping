---
title: SNP-based Prediction of Xoo Pathotype
subtitle: Training a machine learning model on GWAS data for disease characterization in rice
keywords: [xoo, bacterial-blight]
authors: 
- name: Jan Emmanuel G. Samson
  email: jgsamson@up.edu.ph
kernelspec:
  name: python3
  display_name: 'Python 3'
---

## Avirulence Genes in PXO99A

```{code-cell} python3
:tags: [remove-input]
from pygenomeviz import GenomeViz
from pygenomeviz.parser import Gff

gff_path = "assets/pxo99a.gff"
gff = Gff(gff_path)

avr_genes = { key: [] for key in ("id", "start", "end") }

gv = GenomeViz(fig_track_height=0.5)

track = gv.add_feature_track(name="X. oryzae", segments=(150000, 4200000))
track.add_sublabel()

segment = track.get_segment()
for feature in gff.extract_features("CDS"):
    gene_name = str(feature.qualifiers.get("gene", [""])[0])
    if gene_name.startswith("avr"):
        avr_genes["id"].append(feature.id)        
        avr_genes["start"].append(int(feature.location._start))
        avr_genes["end"].append(int(feature.location._end))

        segment.add_features(feature, plotstyle="bigarrow", label="gene")

fig = gv.plotfig()
```

```{code-cell} python3
:tags: [remove-input]
import polars as pl
from great_tables import loc, style

df = pl.DataFrame(avr_genes).select(
    pl.col("id").str.replace("cds-", "").alias("Identifier"),
    pl.col("start").alias("Start"),
    pl.col("end").alias("End"),
).with_columns(
    Length=pl.col("End") - pl.col("Start")
)

df.style \
    .tab_header(title="Xoo Avirulence Genes", subtitle=f"Strain PXO99A harbors {df.height} TAL genes") \
    .tab_style(
        style.text(weight="bold", align=""), loc.body(columns="Identifier")
    ) \
    .tab_style(
        style=[style.fill(color="aliceblue"), style.text(align="center")], locations=loc.body(columns=["Start", "End"])
    ) \
    .tab_style(
        style=[style.fill(color="papayawhip"), style.text(align="center")], locations=loc.body(columns="Length")
    ) \
    .tab_spanner("Coordinates", ["Start", "End"])
```
