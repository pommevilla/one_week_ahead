#!/usr/bin/env bash
# ---------------------------
# Creates the Snakemake DAG
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

snakemake --dag | dot -Tpng > figures/snakemake_dag.png