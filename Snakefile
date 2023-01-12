include: "rules/common.smk"

rule targets:
    input:
        "figures/snakemake_dag.png",
        "data/dnr_data/dnr_combined.csv",
        COMPRESSED_STATIONS_FILES,
        "data/weather/all_stations.csv",
        "data/weather/all_stations_prepared.csv",
        ".hab_prediction_env_restored"

rule restore_renv:
    input:
        r_script = "code/restore_renv.R"
    output:
        touch(".hab_prediction_env_restored")
    log:
        err = "logs/restore_r.err",
        out = "logs/restore_r.out"
    conda:
        "environment.yml"
    shell:
        """
        {input.r_script} 2> {log.err} 1> {log.out}
        """

rule generate_snakemake_dag:
    input:
        script = "code/make_snakemake_dag.sh",
    output:
        "figures/snakemake_dag.png",
    log:
        log = "logs/generate_snakemake_dag.txt"
    conda:
        "environment.yml"
    shell:
        """
        {input.script} 2> {log}
        """

rule combine_dnr_data:
    input:
        renv = ".hab_prediction_env_restored",
        script = "code/dnr_data/combine_DNR_data.R"
    output:
        "data/dnr_data/dnr_combined.csv"
    log:
        log = "logs/combine_dnr_data.txt"
    conda:
        "environment.yml"
    shell:
        """
        {input.script} 2> {log}
        """

include: "rules/weather_data.smk"

