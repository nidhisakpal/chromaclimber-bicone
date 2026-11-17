# ChromaClimber Color Bicone

MATLAB tools for cleaning ChromaClimber color-sensor logs and mapping calibrated measurements into an interactive hue–saturation–lightness-inspired bicone.

## Repository contents

- `clean_chromaclimber_logs.m` — converts the original wide Excel logs into one row per measurement.
- `chromaclimber_coordinates.m` — calculates calibrated and raw-derived bicone coordinates.
- `plot_chromaclimber_bicone.m` — opens the interactive 3-D MATLAB figure with room, lighting, integration-time, color, and error filters.
- `run_chromaclimber_bicone.m` — one-click entry point.
- `condition_summary.csv` — condition-level counts, accuracy, and lightness bounds for the verified dataset.
- `column_dictionary.csv` — definitions for the generated tidy-data columns.
- `audit_notes.csv` and `verification.json` — data-processing and validation notes.
- `input_workbooks/README.md` — required workbook layout and filenames.

## Quick start

1. Place one calibrated-stage `.xlsx` workbook for each environment in `input_workbooks/`. The filenames must contain `GITC`, `MECHE`, and `Swissler` respectively.
2. Set MATLAB's Current Folder to this repository.
3. Run:

```matlab
run_chromaclimber_bicone
```

If no existing cleaned CSV is present, the entry point calls the cleaning pipeline automatically. The original workbooks are never modified. Generated CSV/XLSX outputs are written to `matlab_output/`.

To run the steps directly:

```matlab
[T, Conditions] = clean_chromaclimber_logs;
plot_chromaclimber_bicone(T);
```

## Bicone mapping

The calibrated view uses the hue, lightness, and saturation already logged by the robot firmware:

```text
H = HueLogged mod 1
S = SaturationLogged
L = LightnessLogged
```

Within each room × lighting × integration-time condition, lightness is normalized as

```text
Ln = (L - Lmin) / (Lmax - Lmin)
z  = 2Ln - 1
r  = (1 - |z|)S
x  = r cos(2πH)
y  = r sin(2πH)
```

Measured saturation is retained, so measurements may appear inside the bicone rather than only on its outer surface. The firmware saturation is `(maxRGB-minRGB)/maxRGB`; therefore, this is an HSL-inspired visualization rather than conventional HSL or a perceptually uniform color space.

## Plot interpretation

- Point color represents the intended projected color.
- Circles are correctly classified readings.
- Crosses are incorrectly classified readings.
- Diamonds are nominal color targets, not measured calibration references.
- Repeated coordinates are retained without artificial jitter.
- Accuracy is computed from the robot's logged final color index, not reconstructed from rounded hue values.
- The raw-RGB-derived view uses raw RGB from the same calibrated-stage runs; it is not the earlier 13-classroom pre-calibration experiment.

## Verified calibrated-stage dataset

The validation summary used to check this pipeline contains:

- 3 environments: GITC Lecture Hall, MECHE Lecture Hall, and Swissler Lab
- 2 ambient-lighting conditions
- 3 integration times: 60, 300, and 600 ms
- 8 projected colors
- 2,784 total measurements
- 2,617 logged correct classifications
- 94.0% sample-weighted accuracy

The earlier 13-classroom experiment was collected before the black–white–red calibration and is a separate dataset.

## Requirements

- MATLAB R2020a or later
- No third-party MATLAB toolbox is required
