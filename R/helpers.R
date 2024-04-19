benchmark <- function(FUN, n, package) {
    name <- deparse(substitute(FUN))
    timings <- double(length = n)
    for (i in seq_len(n)) {
        start <- Sys.time()
        result <- FUN()
        end <- Sys.time()
        gc()
        timings[i] <- as.numeric(difftime(end, start, units = "secs"))
    }
    list(
        benchmark = name,
        package = package,
        result = result,
        timings = timings
    )
}
