include: "rules/common.smk"
# unique_stations = set()

# with open("data/stations_nearest_lakes.txt") as fin:
#     next(fin)
#     for line in fin:
#         station = line.strip().split('\t')[1]
#         unique_stations.add(station)

rule targets:
    input:
        "figures/snakemake_dag.png",
        "data/dnr_combined.csv",
        expand("data/weather/{station}.csv.gz", station=unique_stations),
        ".cleaning_done"

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
        script = "code/combine_DNR_data.R"
    output:
        "data/dnr_combined.csv"
    log:
        log = "logs/combine_dnr_data.txt"
    conda:
        "environment.yml"
    shell:
        """
        {input.script} 2> {log}
        """

include: "rules/weather_data.smk"

