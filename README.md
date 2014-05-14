OaH Utils
=========

A set of scripts to help with infrequent activities, like loading GSE/FHA limits.

#### load-county-limits.py

Load limits for a (state, county) pairs from MS Excel files into db.

##### Will work with data on 1st worksheet in the xls file.

##### First row is skipped. So if your xls file doesn't have column names in row 1, some data can be lost.

##### possible args:

  --fha         - path to xls file that holds FHA limits, default `fha-limits.xlsx`

  --gse         - path to xls file that hold GSE limits, default `gse-limits.xlsx`

  --state_row   - column number that stores state value, default `12`

  --county_row  - column number that stores county value, default `13`

  --limit_row   - column number that stores limit value, default `6`

