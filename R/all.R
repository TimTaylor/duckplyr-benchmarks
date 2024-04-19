if (interactive()) {
    root    <- here::here()
    files <- c(sprintf("dp%d-12-months.rds", 1:4), sprintf("dt%d-12-months.rds", 1:4))
    INFILES <- file.path(root, "output", files)
    OUTFILE_CSV <- file.path(root, "output", "all-12-months.csv")
    OUTFILE_RDS <- file.path(root, "output", "all-12-months.rds")
} else {
    args    <- commandArgs(trailingOnly = TRUE)
    n_args <- length(args)
    INFILES <- rev(rev(args)[-c(1L, 2L)])
    OUTFILE_CSV <- args[n_args - 1L]
    OUTFILE_RDS <- args[n_args]
}

library(dplyr, include.only = c("tibble", "bind_rows", "select", "summarise", "left_join", "mutate", "rename"))
library(tidyr, include.only = "pivot_wider")
print(INFILES)

dat <- INFILES |>
    lapply(readRDS) |>
    lapply(with, tibble(package, benchmark, median = median(timings), output = list(result))) |>
    bind_rows()

results <-
    dat |>
    select(-median) |>
    pivot_wider(names_from = "package", values_from = "output") |>
    summarise(equal_output = isTRUE(all.equal(duckplyr, data.table)), .by = benchmark)

timings <- dat |>
    select(-output) |>
    pivot_wider(names_from = "package", values_from = "median") |>
    left_join(results, by = "benchmark") |>
    mutate(
        benchmark = sub("gh", "Query ", benchmark, fixed = TRUE),
        "dt/dp" = data.table / duckplyr
    )

(out <- list(
    duckdb = packageVersion("duckdb"),
    duckplyr = packageVersion("duckplyr"),
    data.table = packageVersion("data.table"),
    timings = timings
))

write.csv(timings, file = OUTFILE_CSV, row.names = FALSE)
saveRDS(out, file = OUTFILE_RDS)
