# ChromaClimber Color Bicone

Tools and data for cleaning ChromaClimber color-sensor logs and mapping calibrated measurements into an interactive hue–saturation–lightness-inspired bicone.

![Calibrated ChromaClimber measurements mapped to a bicone](ChromaClimber_Bicone_Preview.png)

## Included

- **Interactive browser viewer:** `ChromaClimber_Bicone_Interactive.html`
- **MATLAB cleaning pipeline:** `clean_chromaclimber_logs.m`
- **Shared coordinate calculations:** `chromaclimber_coordinates.m`
- **Interactive MATLAB plot:** `plot_chromaclimber_bicone.m`
- **One-click MATLAB entry point:** `run_chromaclimber_bicone.m`
- **Cleaned data:** `ChromaClimber_Cleaned.csv` and `ChromaClimber_Cleaned.xlsx`
- **Original calibrated-stage workbooks:** `input_workbooks/`
- **Audit and summary files:** `condition_summary.csv`, `audit_notes.csv`, `column_dictionary.csv`, and `verification.json`

The repository contains all **2,784 calibrated-stage measurements** from the GITC Lecture Hall, MECHE Lecture Hall, and Swissler Lab, collected with room lights on/off and integration times of 60, 300, and 600 ms.

> The earlier 13-classroom pre-calibration dataset is not included in these workbooks.

## Quick start

### Interactive browser plot

Download the repository and open:

```text
ChromaClimber_Bicone_Interactive.html
```

The viewer is self-contained and works offline. Drag to rotate, scroll to zoom, hover over points for source information, and use the filters to select environment, lighting, integration time, color, representation, and classification errors.

### MATLAB

Set MATLAB's Current Folder to the repository folder and run:

```matlab
run_chromaclimber_bicone
```

To rebuild the cleaned files from the original workbooks:

```matlab
[T, Conditions] = clean_chromaclimber_logs;
plot_chromaclimber_bicone(T);
```

Generated MATLAB outputs are written to `matlab_output/`. The original workbooks are never modified.

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

Measured saturation is retained, so measurements may lie inside the bicone rather than only on its outer surface. The firmware's saturation is `(maxRGB-minRGB)/maxRGB`, so this is an HSL-inspired visualization rather than standard HSL or a perceptually uniform color space.

## Data interpretation

- Marker color represents the intended projected color.
- Circles are correctly classified readings.
- Crosses are incorrectly classified readings.
- Diamonds are nominal RGB target coordinates, not measured calibration references.
- Repeated coordinates are retained and may overlap; no jitter is added.
- The displayed accuracy uses the robot's logged final color index rather than a reclassification from rounded values.
- The raw-RGB-derived view uses raw RGB from the same calibrated-stage runs; it is not the earlier 13-classroom pre-calibration experiment.

## Requirements

- Interactive HTML: a modern desktop browser
- MATLAB scripts: base MATLAB R2020a or later
- No third-party MATLAB toolbox is required

## Verified dataset summary

- 3 environments
- 2 lighting conditions
- 3 integration times
- 8 projected colors
- 2,784 total measurements
- 2,617 logged correct classifications
- 94.0% sample-weighted accuracy

See `README.txt` for detailed methods, provenance notes, and figure-caption guidance.
