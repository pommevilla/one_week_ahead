rule download_weather_data:
    input:
        script = "code/weather/get_station_data.bash",
        stations_nearest_lakes = "data/stations_nearest_lakes.txt"
    output:
        expand("data/weather/{station}.csv.gz", station=unique_stations),
        temp(touch(".weather_data_download_complete"))
    log:
        err = "logs/download_weather_data.err",
        out = "logs/download_weather_data.out"
    conda:
        "../environment.yml"
    threads: 4
    shell:
        """
        {input.script} {input.stations_nearest_lakes} 2> {log.err} 1> {log.out}
        """

rule clean_weather_data:
    input:
        ".weather_data_download_complete" 
    output:
        temp(".cleaning_done")
    log:
        err = "logs/clean_weather_stations.err",
        out = "logs/clean_weather_stations.out"
    shell:
        """
        rm data/weather/US*.csv.gz.* .weather_data_download_complete
        touch .cleaning_done
        """
