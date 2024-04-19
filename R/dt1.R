# Timings we will run:
# https://github.com/Tmonster/duckplyr_demo/blob/main/duckplyr/q01_tip_avg_by_dow_and_hour.R

if (interactive()) {
    root           <- here::here()
    INFILE_TAXI    <- file.path(root, "data", "taxi-data-2019-partitioned-3-months.csv")
    INFILE_ZONE    <- file.path(root, "data", "zone_lookups.csv")
    INFILE_CLASSES <- file.path(root, "data", "classes.rds")
    INFILE_HELPERS <- file.path(root, "R", "helpers.R")
    N_REPS         <- 5L
    OUTFILE        <- file.path(root, "output", "dt1-3-months.rds")
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

# function to run
gh1 <- function() {
    setDT(taxi_dat)
    out <-
        taxi_dat[total_amount > 0
        ][,let(tip_pct = 100 * tip_amount / total_amount,
               dn = wday(pickup_datetime),
               hr = hour(pickup_datetime))
        ][,.(avg_tip_pct = mean(tip_pct), n = .N),by = c("dn", "hr")
        ][order(avg_tip_pct, decreasing = TRUE)]
    setDF(taxi_dat)
    setDF(out)[]
}


cat(" - data.table benchmark 1: Sourcing helper functions and checking required repetitions\n")
source(INFILE_HELPERS)
reps <- as.integer(N_REPS)
if (is.na(reps))
    stop("Invalid value for the number of repetitions")

cat(" - data.table benchmark 1: Loading taxi data\n")
col_classes  <- readRDS(INFILE_CLASSES)
taxi_dat <- fread(INFILE_TAXI, colClasses = col_classes, na.strings = "", data.table = FALSE)
invisible(gc())

cat(sprintf(" - data.table benchmark 1: running %d iterations\n", reps))
res <- benchmark(gh1, n = reps, package = "data.table")

saveRDS(res, OUTFILE)

cat(" - duckplyr benchmark 1: Finished! \n\n")
