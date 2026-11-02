# ECON 8833: Event Studies and Staggered Difference-in-Differences

This repository contains two Stata analyses for ECON 8833. The first script studies conventional event-study specifications and normalization choices. The second applies staggered difference-in-differences estimators to treatment cohorts that enter at different times.

## Files

### `01_conventional_event_study.do`

This script uses three simulated datasets to demonstrate how conventional event-study estimates depend on the construction of relative-time indicators and identifying restrictions. It covers:

- manual creation of event-time leads and lags;
- a standard two-way fixed-effects event-study regression;
- alternative reference-period and average-pre-period normalizations;
- constrained regression with `cnsreg`;
- differential unit-type time trends;
- comparisons of zero-pre-trend, “poor man's” trend-control, and end-cap specifications; and
- coefficient plots illustrating how specification choices affect estimated dynamic treatment effects.

Required input files:

- `es_dataset_one.dta`
- `es_dataset_two.dta`
- `es_dataset_three.dta`

### `02_staggered_did.do`

This script analyzes out-of-pocket medical spending in a panel where hospitalization occurs in different waves. It covers:

- descriptive treatment-cohort statistics;
- a static two-way fixed-effects estimate using `reghdfe`;
- a conventional event-study regression;
- sensitivity analysis with `honestdid`;
- Callaway–Sant'Anna staggered DID estimation using `csdid`;
- comparison of conventional and staggered event-study estimates; and
- alternative pre-period and endpoint constraints.

Required input file:

- `hrs_eventdata.csv`, or another delimited file containing the same variables.

The analysis expects variables including `hhidpn`, `wave`, `wave_hosp`, and `oop_spend`.

## Software requirements

The scripts are written for Stata 16 or later. They use the following community-contributed commands:

- `coefplot`
- `reghdfe`
- `estout` (`eststo` and `esttab`)
- `honestdid`
- `csdid`
- `event_plot`

Install the SSC packages as needed:

```stata
ssc install coefplot
ssc install reghdfe
ssc install estout
ssc install csdid
ssc install event_plot
```

`honestdid` may require installation from its maintained Stata distribution rather than SSC. Consult the package documentation for the current installation command.

## Running the scripts

Both scripts accept optional path arguments, so no personal computer path is required.

Run the conventional event-study analysis with a data directory and an output directory:

```stata
do 01_conventional_event_study.do "path/to/simulated_data" "path/to/output"
```

Run the staggered DID analysis with the input file and output directory:

```stata
do 02_staggered_did.do "path/to/hrs_eventdata.csv" "path/to/output"
```

If arguments are omitted, the scripts look for the data in the current working directory and write results there.

## Outputs

Depending on the script, outputs include:

- timestamped Stata log files;
- event-study coefficient plots in PDF or PNG format; and
- a LaTeX regression table for the static two-way fixed-effects estimate.

The datasets are not included in this repository.
