# Xiaolangdi bathymetric survey planning: data and code

This package contains the data and MATLAB code needed to reproduce the numerical analyses and Figures 3–8 of the Xiaolangdi survey-planning manuscript. It includes the native-resolution cropped DEM, three mapping lines, evaluation boundary, and the seven raw GPS days used in the study.

## Start here

Open this folder in MATLAB, then run:

```matlab
run_figures                 % Fast reproduction from bundled reference results
run_all                     % Recalculate from raw GPS and DEM, then plot
```

The two commands have deliberately different purposes. `run_figures` does not claim to recompute a DEM reconstruction: it uses the clearly labelled `reference/` snapshots. `run_all` calculates its results from `data/raw/`, writes them to `results/`, and plots those newly calculated results. The reference files are used only for comparisons and the colour palette during the full calculation.

The full calculation evaluates 13,110,629 DEM cells for each of 33 layouts. This is a substantial computation. Completed layout results are reused only when their input/code/settings fingerprint matches. Keep `results/survey/cases/` to resume an interrupted reconstruction.

For individual stages:

```matlab
root = setup_project;
step01_calibrate_turning(root);
step02_reconstruct_bathymetry(root);
step03_fit_responses(root);
step04_prepare_figure_data(root);
step05_calculate_crossings(root);
run_figures("computed");
```

Each stage requires the preceding stage's results. Run `check_environment` to check the installed dependencies. See `validation/VALIDATION.md` for the exact scope of the delivery tests.

## Environment

- Developed and checked with MATLAB R2024b on Windows. Other releases/platforms have not been certified.
- Mapping Toolbox: georeferenced DEM input and map coordinates.
- Image Processing Toolbox: the polygon evaluation mask.
- Statistics and Machine Learning Toolbox: spatial searches and distribution statistics.
- Optimization Toolbox: the constrained monotone response fits.
- Python 3 with `pypdf==6.10.0`, for exact PDF page dimensions and uniform 9 pt text. Install with `python -m pip install -r requirements.txt`.
- Times New Roman for the publication figures. A substituted font can change text placement.

The plotting helper calls `python` on PATH. If needed, point it to an installed interpreter **before plotting**, for example:

```matlab
setenv('IJSR_PYTHON','C:/path/to/python.exe');
run_figures
```

No original author directory, Codex installation, external download, or network connection is required at run time once the dependencies are installed. MATLAB is required; this package has not been ported to GNU Octave. Allow several GB for intermediate full-resolution surfaces and routes, in addition to the delivered package; 16 GB or more RAM is recommended.

## Project layout

| Folder / entry point | Contents |
|---|---|
| `data/raw/` | Cropped 0.5 m DEM, accepted geometry, unfiltered daily GPS |
| `config/layout_design.csv` | The 33 adopted layout definitions, without error or time results |
| `analysis/` | Five computation stages and numerical configuration |
| `src/+xldturn/` | GPS preparation, blocks, calibration, bootstrap, duration prediction |
| `src/+xldsurvey/` | Routes, observations, streamwise auxiliary lines, natural-neighbour reconstruction |
| `src/` | Response fitting, decisions, crossing analysis, figure-data preparation |
| `plotting/` | Figure generation and shared vector-PDF export |
| `reference/` | Compact frozen result data for quick plotting and numerical comparison |
| `figures/reference/` | PDFs regenerated from the bundled reference results, plus plotted CSV data |
| `figures/computed/` | PDFs made from a full new calculation; created by `run_all` |
| `results/` | Generated calculation results; not required for the fast reference route |
| `validation/` | Delivery checks and file integrity manifest |

## Figure-to-data mapping

| Figure | Main computation | Figure function | Delivered numerical inputs |
|---|---|---|---|
| 3: GPS, calibration, daily time shares | Stage 1 | `plot_segmented_gps`, `add_turning_analysis_panels` | `reference/turning/` |
| 4: four reconstruction/error examples | Stages 2 and 4 | `plot_reconstruction_draft` | `reference/reconstruction_and_rmse_time.mat`: `Map`, `Surfaces` |
| 5: RMSE–time comparisons | Stages 2–4 | `plot_combined_rmse_time` | Same MAT: `Time`, fits, curves, crossings; `reference/layouts.csv` |
| 6: fleet/path/spacing decisions | Stage 3 | `plot_engineering_decisions` | `reference/rmse_only_results.mat`; generated `Fig06_decision_grid.csv` |
| 7: duration checks and parameter sensitivity | Stage 1 | `plot_turning_model_discussion` | `reference/turning/Windows.csv`, bootstrap and preprocessing tables |
| 8: turning-cost crossing response | Stage 5 | `plot_crossover_semilog` | `reference/normalized_crossover_data.mat`; generated sweep CSV |

The small rasters in the Figure 4 MAT file are **display samples**, not the full-resolution evaluation data. RMSE is always calculated on the full common evaluation domain. Stage 2 generates full-resolution surfaces; Stage 4 samples them for plotting. All individual layout errors are also available in `reference/layouts.csv`.

## Numerical conventions

Platform A is Platform 2023, and Platform B is Platform 2020. There are 18 BCS layouts and 15 PCZ layouts, or 66 platform–layout pairs. `config/layout_design.csv` freezes the exact experiment, including six dense extensions. It is not a table of fitted or reconstructed outcomes.

The mapping length is 7,738.31333704798 m. PCZ uses two effective intervals per construction interval; BCS uses one. Model geometry uses a lateral fraction from 0 to 1 internally, corresponding to the paper's eta from -1 to 1. All complete routes include their return segment. Figure-2 artwork is unnecessary to generate these numerical routes.

Turning calibration uses seed 20260814 and 5,000 moving-block bootstrap replicates. Response smoothing uses lambda = 1e-4. Reconstructed values use natural neighbours inside the input convex hull and explicitly recorded nearest-neighbour filling outside it. The same evaluation cells are retained for every layout. These choices are explicit in `analysis/turning_config.m`, `analysis/rmse_time_config.m`, and the stage functions.

The delivered DEM is a cell-aligned rectangular crop with a 10 m halo around the accepted polygon. Elevations were not resampled. The polygon, rather than the crop rectangle, defines the RMSE domain. Consequently, the count of valid cells outside the evaluation polygon is smaller than in the original full DEM; this does not change the evaluation domain or its elevations.

See `DATA_DICTIONARY.md` for coordinates, units, timestamps, and the distinction between raw records and derived results.
