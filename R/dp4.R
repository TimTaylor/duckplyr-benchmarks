# Timings we will run:
# https://github.com/Tmonster/duckplyr_demo/blob/main/duckplyr/q04_number_of_no_tip_trips.R

if (interactive()) {
    root           <- here::here()
    INFILE_TAXI    <- file.path(root, "data", "taxi-data-2019-partitioned-3-months.csv")
    INFILE_ZONE    <- file.path(root, "data", "zone_lookups.csv")
    INFILE_CLASSES <- file.path(root, "data", "classes.rds")
    INFILE_HELPERS <- file.path(root, "R", "helpers.R")
    N_REPS         <- 5L
    OUTFILE        <- file.path(root, "output", "dp4-3-months.rds")
} else {
    args           <- commandArgs(trailingOnly = TRUE)
    INFILE_TAXI    <- args[1L]
    INFILE_ZONE    <- args[2L]
    INFILE_CLASSES <- args[3L]
    INFILE_HELPERS <- args[4L]
    N_REPS         <- args[5L]
    OUTFILE        <- args[6L]
}

library(duckplyr, warn.conflicts = FALSE)
library(data.table, warn.conflicts = FALSE)
options(duckdb.materialize_message = FALSE)

# function to run
gh4 <- function() {
    zone_map <- as_duckplyr_df(zone_dat)

    num_trips_per_borough <-
        taxi_dat |>
        as_duckplyr_df() |>
        filter(total_amount > 0) |>
        inner_join(zone_map, by = join_by(pickup_location_id == LocationID)) |>
        inner_join(zone_map, by = join_by(dropoff_location_id == LocationID)) |>
        mutate(pickup_borough = Borough.x, dropoff_borough = Borough.y) |>
        select(pickup_borough, dropoff_borough, tip_amount) |>
        summarise(num_trips = n(), .by = c(pickup_borough, dropoff_borough))

    num_trips_per_borough_no_tip <-
        taxi_dat |>
        as_duckplyr_df() |>
        filter(total_amount > 0, tip_amount == 0) |>
        inner_join(zone_map, by = join_by(pickup_location_id == LocationID)) |>
        inner_join(zone_map, by = join_by(dropoff_location_id == LocationID)) |>
        mutate(pickup_borough = Borough.x, dropoff_borough = Borough.y) |>
        summarise(
            num_zero_tip_trips = n(),
            .by = c(pickup_borough, dropoff_borough)
        )

    out <-
        num_trips_per_borough |>
        inner_join(
            num_trips_per_borough_no_tip,
            by = join_by(pickup_borough, dropoff_borough)
        ) |>
        mutate(
            num_trips = num_trips,
            percent_zero_tips_trips = 100 * num_zero_tip_trips / num_trips
        ) |>
        select(pickup_borough, dropoff_borough, num_trips, percent_zero_tips_trips) |>
        arrange(desc(percent_zero_tips_trips), pickup_borough, dropoff_borough) |>
        as.data.frame()

    nrow(out) # force it's collection (just in case)
    out
}

cat(" - duckplyr benchmark 4: Sourcing helper functions and checking required repetitions\n")
source(INFILE_HELPERS)
reps <- as.integer(N_REPS)
if (is.na(reps))
    stop("Invalid value for the number of repetitions")

cat(" - duckplyr benchmark 4: Loading taxi data\n")
zone_dat <- fread(INFILE_ZONE, na.strings = "", data.table = FALSE)
col_classes  <- readRDS(INFILE_CLASSES)
taxi_dat <- fread(INFILE_TAXI, colClasses = col_classes, na.strings = "", data.table = FALSE)
invisible(gc())

cat(sprintf(" - duckplyr benchmark 4: running %d iterations\n", reps))
res <- benchmark(gh4, n = reps, package = "duckplyr")

saveRDS(res, OUTFILE)

cat(" - duckplyr benchmark 4: Finished! \n\n")
