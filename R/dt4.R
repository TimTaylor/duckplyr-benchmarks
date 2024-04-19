# Timings we will run:
# https://github.com/Tmonster/duckplyr_demo/blob/main/duckplyr/q04_number_of_no_tip_trips.R

if (interactive()) {
    root           <- here::here()
    INFILE_TAXI    <- file.path(root, "data", "taxi-data-2019-partitioned-3-months.csv")
    INFILE_ZONE    <- file.path(root, "data", "zone_lookups.csv")
    INFILE_CLASSES <- file.path(root, "data", "classes.rds")
    INFILE_HELPERS <- file.path(root, "R", "helpers.R")
    N_REPS         <- 5L
    OUTFILE        <- file.path(root, "output", "dt4-3-months.rds")
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
gh4 <- function() {
    setDT(taxi_dat)
    setDT(zone_dat)
    out <- taxi_dat[total_amount > 0, .(pickup_location_id, dropoff_location_id, tip_amount)]
    ntpb <- out[,.(num_trips = .N), by = pickup_location_id:dropoff_location_id]
    out <- out[tip_amount == 0,.(num_zero_tip_trips = .N),
               by = pickup_location_id:dropoff_location_id
           ][ntpb, on = .NATURAL
           ][zone_dat, on = "pickup_location_id == LocationID", nomatch = NULL
           ][zone_dat, on = "dropoff_location_id == LocationID", nomatch = NULL]

    setnafill(out, fill = 0, nan = NA, cols = "num_zero_tip_trips")
    setnames(out, c("Borough", "i.Borough"), c("pickup_borough", "dropoff_borough"))
    out <- out[, .(num_trips = sum(num_trips),num_zero_tip_trips = sum(num_zero_tip_trips)), by = c("pickup_borough", "dropoff_borough")]
    out <- out[, let(percent_zero_tips_trips = 100 * num_zero_tip_trips / num_trips, num_zero_tip_trips = NULL)]
    setorder(out, -percent_zero_tips_trips, pickup_borough, dropoff_borough)
    setDF(taxi_dat)
    setDF(zone_dat)
    setDF(out)[]
}

cat(" - data.table benchmark 4: Sourcing helper functions and checking required repetitions\n")
source(INFILE_HELPERS)
reps <- as.integer(N_REPS)
if (is.na(reps))
    stop("Invalid value for the number of repetitions")

cat(" - data.table benchmark 4: Loading taxi data\n")
zone_dat <- fread(INFILE_ZONE, na.strings = "", data.table = FALSE)
col_classes  <- readRDS(INFILE_CLASSES)
taxi_dat <- fread(INFILE_TAXI, colClasses = col_classes, na.strings = "", data.table = FALSE)
invisible(gc())

cat(sprintf(" - data.table benchmark 4: running %d iterations\n", reps))
res <- benchmark(gh4, n = reps, package = "data.table")

saveRDS(res, OUTFILE)

cat(" - data.table benchmark 4: Finished! \n\n")
