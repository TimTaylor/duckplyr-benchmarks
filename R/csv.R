if (interactive()) {
    root            <- here::here()
    INFILE          <- file.path(root, "data", "taxi-data-2019-partitioned.zip")
    MONTHS          <- 3L
    OUTFILE_TAXI    <- file.path(root, "data", "taxi-data-2019-partitioned-3-months.csv")
    OUTFILE_ZONE    <- file.path(root, "data", "zone_lookups.csv")
    OUTFILE_CLASSES <- file.path(root, "data", "classes.rds")
} else {
    args            <- commandArgs(trailingOnly = TRUE)
    INFILE          <- args[1L]
    MONTHS          <- args[2L]
    OUTFILE_TAXI    <- args[3L]
    OUTFILE_ZONE    <- args[4L]
    OUTFILE_CLASSES <- args[5L]
}

# check months
months <- as.integer(MONTHS)
if (length(months) != 1L || is.na(months) || months < 1L || months > 12L)
    stop("`MONTHS` must be an integer between 1 and 12 (inclusive)")

# Expected files (easier to do here than in makefile)
taxi <- expand.grid(month = 1:12, data = 0:7)
taxi <- sprintf("%s/month=%d/data_%d.parquet", tools::file_path_sans_ext(INFILE), taxi$month, taxi$data)
zone <- file.path(dirname(INFILE), "zone_lookups.parquet")

# Unzip the data if not all files present.
if (!all(file.exists(taxi)) || !file.exists(zone)) {
    utils::unzip(INFILE, exdir = dirname(INFILE), unzip = getOption("unzip"))
}

# Load taxi data
query <- sprintf(
    "FROM '%s/*/*.parquet' WHERE month IN (%s)",
    tools::file_path_sans_ext(INFILE),
    toString(rev((12:1)[seq_len(months)]))
)
taxi_dat <- duckdb:::sql(query)

# Load zone lookup
query    <- sprintf("FROM '%s.parquet'", tools::file_path_sans_ext(OUTFILE_ZONE))
zone_dat <- duckdb:::sql(query)

# Save both data frames to csv for reading back in.
# This is probably superfluous but I'm doing it to avoid any potential altrep
# stuff coming in to play in the comparisons.
data.table::fwrite(taxi_dat, OUTFILE_TAXI, na = "")
data.table::fwrite(zone_dat, OUTFILE_ZONE, na = "")

# Also need to save the column classes for reloading data
col_classes <- sapply(taxi_dat, \(x) .class2(x)[1L])
saveRDS(col_classes, OUTFILE_CLASSES)
