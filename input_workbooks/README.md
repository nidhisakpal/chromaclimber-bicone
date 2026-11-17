# Input workbooks

Place one calibrated-stage workbook for each environment in this folder before running `clean_chromaclimber_logs.m`:

- a filename containing `GITC`
- a filename containing `MECHE`
- a filename containing `Swissler`

The cleaner reads only worksheets named:

- `60_lights_on`
- `60_lights_off`
- `300_lights_on`
- `300_lights_off`
- `600_lights_on`
- `600_lights_off`

The original workbooks are never edited. Generated tidy CSV/XLSX files are written to `matlab_output/`.

The earlier 13-classroom pre-calibration dataset is separate and is not used by this calibrated-stage plotting pipeline.
