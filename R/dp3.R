# Timings we will run:
# https://github.com/Tmonster/duckplyr_demo/blob/main/duckplyr/q03_popular_manhattan_cab_rides.R

if (interactive()) {
    root           <- here::here()
    INFILE_TAXI    <- file.path(root, "data", "taxi-data-2019-partitioned-3-months.csv")
    INFILE_ZONE    <- file.path(root, "data", "zone_lookups.csv")
    INFILE_CLASSES <- file.path(root, "data", "classes.rds")
    INFILE_HELPERS <- file.path(root, "R", "helpers.R")
    N_REPS         <- 5L
    OUTFILE        <- file.path(root, "output", "dp3-3-months.rds")
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
gh3 <- function() {
    zone_map <- as_duckplyr_df(zone_dat) |> filter(Borough == "Manhattan")

    out <-
        taxi_dat |>
        as_duckplyr_df() |>
        filter(total_amount > 0) |>
        inner_join(zone_map, by = join_by(pickup_location_id == LocationID)) |>
        inner_join(zone_map, by = join_by(dropoff_location_id == LocationID)) |>
        select(start_neighbourhood = Zone.x, end_neighbourhood = Zone.y) |>
        summarise(
            num_trips = n(),
            .by = c(start_neighbourhood, end_neighbourhood),
        ) |>
        arrange(desc(num_trips), start_neighbourhood, end_neighbourhood) |>
        as.data.frame()

    nrow(out) # force it's collection (just in case)
    out
}

cat(" - duckplyr benchmark 3: Sourcing helper functions and checking required repetitions\n")
source(INFILE_HELPERS)
reps <- as.integer(N_REPS)
if (is.na(reps))
    stop("Invalid value for the number of repetitions")

cat(" - duckplyr benchmark 3: Loading taxi data\n")
zone_dat <- fread(INFILE_ZONE, na.strings = "", data.table = FALSE)
col_classes  <- readRDS(INFILE_CLASSES)
taxi_dat <- fread(INFILE_TAXI, colClasses = col_classes, na.strings = "", data.table = FALSE)
invisible(gc())

cat(sprintf(" - duckplyr benchmark 3: running %d iterations\n", reps))
res <- benchmark(gh3, n = reps, package = "duckplyr")

saveRDS(res, OUTFILE)

cat(" - duckplyr benchmark 3: Finished! \n\n")
