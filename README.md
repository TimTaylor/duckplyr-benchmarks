# Overview

Repository contains code to benchmark duckplyr and data.table. It is based
on the the examples from https://github.com/Tmonster/duckplyr_demo.

## Running

- Clone this repository.
- Edit the `MONTHS` and `REPS` variables at the top of the Makefile.
    - `MONTHS` represents how many months (1-12) of data you want to include.
    - `REPS` is the number of repetitions of each benchmark to perform. If
      primarily used to compare the packages, then with the current gap in
      performance, 5 is likely sufficient. For benchmarking changes in package
      release you will likely want more.
- Once your satisfied you trust the code, run `make` within the cloned folder.

```bash
git clone https://git.sr.ht/~tim-taylor/duckplyr-benchmarks
cd duckplyr-benchmarks
make
```

## Details

- `R/download.R` downloads the zipped taxi data.
- `R/csv.R`:
    - extracts the zipped parquet data.
    - loads the desired MONTHS worth of data in to R.
    - saves the resultant data frame to a csv.
- `R/dp1.R`, `R/dp1.R`, `R/dp1.R`, `R/dp1.R`, `R/dp1.R`, `R/dp1.R`, `R/dp1.R` and `R/dp1.R`
  run the relevant benchmarks saving output to rds files.
- `R/all.csv` brings all timings together in one table and saves this as a csv
  and another rds file which also includes the versions of duckplyr and data.table
  used in the benchmarks.
  
## Interactive use (debugging / exploration)

The files can be run interactively (following the order listed above) but care
must be taken to ensure the input constants (at the top of each file are correct).
