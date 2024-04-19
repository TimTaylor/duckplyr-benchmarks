# Timings we will run:
# https://github.com/Tmonster/duckplyr_demo/blob/main/duckplyr/q03_popular_manhattan_cab_rides.R

if (interactive()) {
    root           <- here::here()
    INFILE_TAXI    <- file.path(root, "data", "taxi-data-2019-partitioned-3-months.csv")
    INFILE_ZONE    <- file.path(root, "data", "zone_lookups.csv")
    INFILE_CLASSES <- file.path(root, "data", "classes.rds")
    INFILE_HELPERS <- file.path(root, "R", "helpers.R")
    N_REPS         <- 5L
    OUTFILE        <- file.path(root, "output", "dt3-3-months.rds")
} else {
    args           <- commandArgs(trailingOnly = TRUE)
    INFILE_TAXI    <- args[1L]
    INFILE_ZONE    <- args[2L]
    INFILE_CLASSES <- args[3L]
    INFILE_HELPERS <- args[4L]
    N_REPS         <- args[5L]
    OUTFILE        <- args[6L]
}

library(data.table, warn.conflicts = FALSE)

# function to benchmark
gh3 <- function() {
    setDT(taxi_dat)
    setDT(zone_dat)
    zone_map <- zone_dat[Borough == "Manhattan"]
    out <-
        taxi_dat[total_amount > 0
        ][zone_map, on = "pickup_location_id == LocationID", nomatch = NULL
        ][zone_map, on = "dropoff_location_id == LocationID", nomatch = NULL
        ][, .(start_neighbourhood = Zone, end_neighbourhood = i.Zone)
        ][, .(num_trips = .N), by = start_neighbourhood:end_neighbourhood]

    setorder(out, -num_trips, start_neighbourhood, end_neighbourhood)
    setDF(taxi_dat)
    setDF(zone_dat)
    setDF(out)[]
}

cat(" - data.table benchmark 3: Sourcing helper functions and checking required repetitions\n")
source(INFILE_HELPERS)
reps <- as.integer(N_REPS)
if (is.na(reps))
    stop("Invalid value for the number of repetitions")

cat(" - data.table benchmark 3: Loading taxi data\n")
zone_dat <- fread(INFILE_ZONE, na.strings = "", data.table = FALSE)
col_classes  <- readRDS(INFILE_CLASSES)
taxi_dat <- fread(INFILE_TAXI, colClasses = col_classes, na.strings = "", data.table = FALSE)
invisible(gc())

cat(sprintf(" - data.table benchmark 3: running %d iterations\n", reps))
res <- benchmark(gh3, n = reps, package = "data.table")

saveRDS(res, OUTFILE)

cat(" - data.table benchmark 3: Finished! \n\n")
