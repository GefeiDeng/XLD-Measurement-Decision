# Data dictionary and provenance

## Coordinate system

Horizontal coordinates are WGS 84 / UTM zone 49N, EPSG:32649, in metres. Bed elevations are in metres relative to the 1985 National Height Datum of China, as specified in the manuscript. The multibeam reference survey was acquired on 23–27 July 2023. The cropped raster retains the original single-precision values and 0.5 m grid; no vertical datum conversion or resampling is performed.

## Raw study inputs

| File | Fields and interpretation |
|---|---|
| `data/raw/dem_cropped.tif` | One-band float32 GeoTIFF. Pixel centres are defined by its georeferencing. NoData sentinel is recorded in the JSON; it must be masked before interpolation. |
| `data/raw/dem_metadata.json` | EPSG, exact NoData value, cell size, expected evaluation-cell count, elevation range. |
| `data/raw/geometry/leftBank.csv` | `Station_m`, `Easting_m`, `Northing_m`; accepted paired left-bank mapping vertices. |
| `data/raw/geometry/rightBank.csv` | Same columns; accepted paired right-bank mapping vertices. |
| `data/raw/geometry/thalweg.csv` | Same columns; clipped measured-DEM thalweg used as the reference mapping line. |
| `data/raw/geometry/evaluation_boundary.csv` | Closed evaluation polygon: `X_m`, `Y_m`, in metres. This, not the DEM rectangle, defines the evaluation area. |
| `data/raw/gps/A_20230706` through `A_20230710` | Platform 2023, one CSV and one MAT per day. |
| `data/raw/gps/B_20200817`, `B_20200823` | Platform 2020, one CSV and one MAT per day. |

GPS CSV columns are `SourceRow`, `Time`, `Easting_m`, `Northing_m`. SourceRow is the original MAT matrix row before selecting that day; it is an audit identifier, not a new sampling sequence. Records have not been filtered, averaged, smoothed, or segmented. Timestamps carry the source clock time without a timezone conversion. The calculation uses within-day elapsed seconds.

The corresponding MAT contains `rawDay`: `Dataset` (Medium = A, Large = B), `DateKey` (YYYYMMDD), `IncludeInModel`, full-precision MATLAB datetime `Time`, `X_m`, `Y_m`, `RawPointCount`, and `SourceRow`. MAT is authoritative for timestamp precision; CSV exposes the same coordinates and times in a readable form. The MAT/CSV pair is intentional, not two different measurements. Unused columns and unrelated measurement days from the original source matrices are excluded.

The accepted three-line geometry is an input to the reproduction, not a claim of untouched field digitization. Its station coordinates and paired vertices retain the geometry actually used in the paper. The computation rebuilds `channelModel` from these CSV files. Internal lateral fractions are 0 (right bank), 0.5 (thalweg), 1 (left bank).

## Layout definition

`config/layout_design.csv` contains one row per unique layout. `CaseID` identifies the path and integer construction intervals; `Path` is BCS or PCZ. `CanonicalRequestedD_m` is the request sent to the route generator. `ConstructionIntervals` is the integer used to build the template. `EffectiveIntervals` is equal to it for BCS and twice it for PCZ. `ActualD_m = L / EffectiveIntervals`; `ActualDstar = ActualD_m / mean_width`. Alias columns record spacing requests that lead to the same discrete layout. No RMSE, platform coefficient, speed, or duration is used as an input here.

## Reference and calculated results

`reference/layouts.csv` contains 66 rows, one per layout/platform pair. Lengths and spacings are metres; heading change is radians; `Coefficient_m_per_rad` is c_v; `BaselineSpeed_mps` is v. Durations use seconds or hours as explicitly indicated. `RMSE_m`, `MAE_m`, `Bias_m`, and `MaximumAbsoluteError_m` summarize reconstructed-minus-reference elevations. `Rstar` normalizes RMSE by the 40.90594482421875 m reference elevation range. Coverage and fill fractions distinguish native natural-neighbour interpolation from exterior nearest-neighbour filling.

`reference/turning/blocks_A.csv` and `blocks_B.csv` contain derived spatial blocks. `Length_m`, `Time_s`, `AbsoluteTurnAngle_rad`, and `LocalBaselineSpeed_mps` lead to observed extra duration; `UseForCalibration` selects the regression blocks. `Summary.csv` reports platform fits, conditional bootstrap limits, time decomposition, and retained/calibration counts. `Daily.csv` reports daily decomposition. `BootstrapDraws.csv` records seeded resampled coefficients. `Windows.csv` records multiscale cumulative-duration checks. `Preprocessing.csv` records the adopted one-factor sensitivity study.

`reference/reconstruction_and_rmse_time.mat` contains figure data, numerical error/time rows, monotone-fit structures, and crossings. `Map` defines the display grid and boundary; each `Surfaces` entry contains sampled prediction/error arrays, the corresponding full-resolution RMSE, and a thinned route overlay. Display thinning is never used for numerical RMSE.

`reference/rmse_only_results.mat` contains only the adopted configuration, layouts, four fitted response models, and two decision maps. Each fitted response uses a constrained smooth fit in log(time)–log(RMSE), followed by shape-preserving cubic interpolation. Decision maps enumerate the minimum fleet under ideal workload sharing, choose a supported path, and interpolate its planning spacing. Unused coefficient-scenario decision maps are not included.

`reference/normalized_crossover_data.mat` contains the 0–500 m/rad coefficient sweep, calibrated-platform points, normalization constants, and consistency checks used for Figure 8. The zero-coefficient result is retained as the horizontal reference; it cannot be plotted as a point on a logarithmic coefficient axis.

After recalculation, `results/turning/`, `results/survey/`, `results/responses/`, and `results/figure_data/` contain the corresponding new outputs. `results/survey/cases/<CaseID>/surface.mat` stores full-resolution prediction vectors in the order of `results/survey/common/evaluation_reference.mat:EvaluationIndices`. Raster indices use MATLAB column-major ordering.
