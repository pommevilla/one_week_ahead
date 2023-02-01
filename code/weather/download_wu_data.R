#!/usr/bin/env Rscript
# ---------------------------
# Downloads weather data from Weather Underground (https://www.wunderground.com/)
# for use downstream. This is not run in the main Snakemake pipeline
# because Weather Underground appears to throttle you if you download too many
# files at a time, causing you to have to rerun the script over and over
# to capture all the data.
# Credit to Schuyler Smith for the creation of this code:
#   https://schuyler-smith.github.io/IA_Lake_Microcystin/weather.html
# Author: Schuyler Smith (github.com/schuyler-smith)
# ---------------------------
library(data.table)

parse_wu_tables <- function(weather_data) {
    weather <- data.table::data.table(
        Station = sapply(strsplit(names(weather_data), "_"), `[[`, 1),
        Date = as.Date(sapply(strsplit(
            names(weather_data), "_"
        ), `[[`, 2))
    )
    weather[, avg_temp := numeric()]
    weather[, avg_humid := numeric()]
    weather[, avg_dew := numeric()]
    weather[, avg_wind := numeric()]
    weather[, avg_gust := numeric()]
    weather[, precip := numeric()]

    for (i in seq_along(weather_data)) {
        weather_table <- weather_data[[i]]
        if (nrow(weather_table) > 1) {
            set(weather, as.integer(i), names(weather)[-c(1:2)], as.list(
                c(
                    avg_temp = as.numeric(str_trim(gsub(".?F", "", weather_table[V1 %in% "Temperature"]$Average))),
                    avg_humid = as.numeric(str_trim(gsub(".?%", "", weather_table[V1 %in% "Humidity"]$Average))),
                    avg_dew = as.numeric(str_trim(gsub(".?F", "", weather_table[V1 %in% "Dew Point"]$Average))),
                    avg_wind = as.numeric(str_trim(gsub(".?mph", "", weather_table[V1 %in% "Wind Speed"]$Average))),
                    avg_gust = as.numeric(str_trim(gsub(".?mph", "", weather_table[V1 %in% "Wind Gust"]$Average))),
                    precip = as.numeric(str_trim(gsub(".?in", "", weather_table[V1 %in% "Precipitation"]$High)))
                )
            ))
        }
    }
    return(data.table(weather))
}

retry_scrape_wu_tables <- function(weather_table, second_station, cores = 1) {
    original_date <- as.Date(weather_table$Date)
    dates <- c(
        original_date,
        as.Date(original_date) - 1,
        as.Date(original_date) + 1,
        as.Date(original_date) - 2,
        as.Date(original_date) + 2
    )
    urls <- c(rbind(
        create_wu_urls(weather_table$Station, dates),
        create_wu_urls(second_station, dates)
    ))
    if (is.na(second_station)) {
        urls <- create_wu_urls(weather_table$Station, dates)
    }
    new_tables <- scrape_wu_tables(urls, 3)
    new_tables <- parse_wu_tables(new_tables)
    new_tables <- new_tables[!(is.na(avg_temp))]
    if (nrow(new_tables) > 0) {
        set(weather_table, 1L, names(weather_table)[-2], new_tables[1, -2])
        return(data.table(weather_table))
    } else {
        return(NULL)
    }
}

create_wu_urls <- function(station, date) {
    urls <- vector()
    for (i in seq_along(station)) {
        for (j in seq_along(date)) {
            urls <- c(
                urls,
                paste0(
                    "https://www.wunderground.com/dashboard/pws/",
                    station[i],
                    "/graph/",
                    date[j],
                    "/",
                    date[j],
                    "/weekly"
                )
            )
        }
    }
    urls <- unique(urls)
    return(urls)
}

scrape_wu_tables <- function(url, cores = 1) {
    print(str_interp("Attempting ${url}"))
    cluster <- parallel::makeCluster(cores, type = "PSOCK")
    doParallel::registerDoParallel(cl = cluster)
    weather_data <-
        foreach::`%dopar%`(foreach::foreach(i = seq_along(url)), {
            data.table::rbindlist(rvest::html_table(rvest::read_html(url[i]), fill = TRUE))
        })
    parallel::stopCluster(cl = cluster)
    names(weather_data) <- paste(sapply(strsplit(url, "/"), `[[`, 6),
        sapply(strsplit(url, "/"), `[[`, 8),
        sep = "_"
    )
    return(weather_data)
}

dnr_data <- read.csv("data/dnr_data/dnr_combined.csv")
station_info <- read.delim("data/station_info.txt")

weather <- data.table::data.table()


unique_stations <- unique(station_info$WU_Station_1)
unique_stations <- station_info %>%
    group_by(WU_Station_1) %>%
    slice_head(n = 1) %>%
    select(WU_Station_1, WU_Station_2)

for (i in seq_along(station_info$WU_Station_1)) {
    print(station_info$Site[i])
    wu_urls <-
        create_wu_urls(
            station_info$WU_Station_1[i],
            dnr_data %>%
                filter(environmental_location %in% station_info$Site[i]) %>%
                pull("collected_date")
        )

    weather_data <- scrape_wu_tables(wu_urls, cores = 3)

    weather_dt <- parse_wu_tables(weather_data)

    for (j in weather_dt[, .I[is.na(avg_temp)]]) {
        new_data <- retry_scrape_wu_tables(weather_dt[j], station_info$WU_Station_2[i], 3)
        if (!(is.null(new_data))) {
            set(weather_dt, as.integer(j), names(weather_dt), new_data)
        }
    }
    weather <-
        rbind(weather, cbind(Location = station_info$Site[i], weather_dt))
}

saveRDS(weather, "data/weather/raw_weather_downloaded.RDS")
readRDS("data/weather/raw_weather_downloaded.RDS")
write.csv(
    weather,
    "data/weather/raw_weather_downloaded.csv",
    row.names = FALSE, quote = FALSE
)
