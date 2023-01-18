# One week ahead...

This repository contains the data and code required to reproduce the results and visualizations from the forthcoming paper "One week ahead prediction of harmful algal blooms in Iowa lakes."

## Repeating the analysis

After cloning the repo, restore the conda environment by doing:

```
mamba env create -f environment.yml
```

Then, activate the environment:

```
conda activate hab_prediction
```

You can then run the pipeline with:

```
snakemake -c 4
```

_(You can also do `snakemake -c 1` to use fewer cores.)_

This will restore the R environment, regenerate all the figures, and render the website.

## DAG of jobs

<p align="center">
  <img src="figures/snakemake_dag.png" />
</p>
