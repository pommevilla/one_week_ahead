TREATMENTS = ["something"]

rule targets:
    "figures/snakemake_dag.png"

rule generate_snakemake_dag:
    input:
        script = "code/make_snakemake_dag.sh"
    output:
        "figures/snakemake_dag.png"