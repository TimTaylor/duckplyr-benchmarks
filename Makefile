MONTHS := 3
REPS := 5

.PHONY: all clean

# directories
REFDIR  := .
SRCDIR  := ${REFDIR}/R
DATADIR := ${REFDIR}/data
OUTDIR  := ${REFDIR}/output

# data source
URL := http://duckplyr-demo-taxi-data.s3-website-eu-west-1.amazonaws.com/taxi-data-2019-partitioned.zip

# data
SUFFIX := ${MONTHS}-months
ZIP := ${DATADIR}/$(notdir ${URL})
DAT := $(addprefix ${DATADIR}/, taxi-data-2019-partitioned-${SUFFIX}.csv zone_lookups.csv classes.rds)

# helper functions
HELPERS := ${SRCDIR}/helpers.R

# outfiles
BENCHMARKS := $(addsuffix -${SUFFIX}.rds, dp1 dp2 dp3 dp4 dt1 dt2 dt3 dt4)
BENCHMARKS := $(addprefix ${OUTDIR}/, ${BENCHMARKS})
ALL := ${OUTDIR}/all-${SUFFIX}.csv ${OUTDIR}/all-${SUFFIX}.rds

all: ${ALL}

${ALL}&: ${SRCDIR}/all.R ${BENCHMARKS}
	Rscript --vanilla $^ ${ALL}

${BENCHMARKS}: ${OUTDIR}/%-${SUFFIX}.rds: ${SRCDIR}/%.R ${DAT} ${HELPERS}
	DUCKPLYR_FALLBACK_AUTOUPLOAD=0 Rscript --vanilla $^ ${REPS} $@

${DAT}&: ${SRCDIR}/csv.R ${ZIP}
	Rscript --vanilla $^ ${MONTHS} ${DAT}

${ZIP}: ${SRCDIR}/download.R
	Rscript --vanilla $^ ${URL} $@

clean:
	rm ${ALL} ${BENCHMARKS}
