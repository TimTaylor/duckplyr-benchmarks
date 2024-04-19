if (interactive()) {
    root    <- here::here()
    URL     <- "http://duckplyr-demo-taxi-data.s3-website-eu-west-1.amazonaws.com/taxi-data-2019-partitioned.zip"
    OUTFILE <- file.path(root, "data", "taxi-data-2019-partitioned.zip")
} else {
    args    <- commandArgs(trailingOnly = TRUE)
    URL     <- args[1L]
    OUTFILE <- args[2L]
}

download.file(URL, OUTFILE, method = "libcurl")
