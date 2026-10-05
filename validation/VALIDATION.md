# Delivery validation

Checked on 5 October 2026 with MATLAB R2024b on Windows.

## Checks actually performed

1. **Raw DEM crop.** The 0.5 m grid was cropped without resampling. The polygon mask within the crop was identical to the corresponding part of the original mask. All 13,110,629 evaluation elevations were compared exactly and were unchanged. The reference elevation range remains 40.90594482421875 m.
2. **Raw GPS calculation.** All seven unfiltered daily records were processed again. Both platform fits, baseline speeds, conditional bootstrap limits, and turning-related time shares were compared with the reference data. See `raw_gps_recalibration.csv` and `turning_model_checks.csv`.
3. **All route geometries and times.** All 33 adopted layouts were generated from the delivered three-line geometry, then evaluated for both platforms. Route lengths, cumulative absolute heading changes, and total times agree with the reference table. See `route_time_comparison.csv` (66 rows).
4. **Two full-grid reconstructions from raw inputs.** BCS_M002 and PCZ_M001 were independently reconstructed from the cropped DEM on the entire 13,110,629-cell domain. The resulting RMSE values agree with the reference values, approximately 2.440005 m and 2.562561 m. See `full_grid_reconstruction.csv` and the two case-check tables.
5. **All downstream numerical relationships.** The four response fits were rebuilt from the delivered layout results. Both decision maps and the 323-point coefficient sweep (including calibrated platform coefficients) were recalculated. The compared fitted curves, decision values, and crossing values matched the reference results. See `reference_recalculation.csv`.
6. **Stage interfaces.** Stages 3–5 were exercised together using the delivered numerical layout data, archived full-resolution example surfaces, and the freshly cropped evaluation-grid metadata. All four example surfaces reproduce their stored full-domain RMSE. This checks the interface between full surfaces and display samples; it is not a new interpolation of the two dense examples.
7. **Portable plotting.** Figures 3–8 were regenerated from inside the requested delivery directory with MATLAB's default paths and this project's paths only. All six PDFs were rendered and visually inspected. Their physical widths and uniform text sizes were checked; see `pdf_checks.csv`.
8. **Dependencies.** MATLAB dependency analysis found only this project and the listed MathWorks products. It does not require the original author directories or third-party MATLAB add-ons. See `matlab_products.csv`.
9. **Resume behaviour.** Identical scientific model values retain the same fingerprint when MAT-file metadata is rewritten; a changed turning coefficient changes the fingerprint. See `resume_fingerprint.csv`.

## Scope limit

**All 33 full-resolution DEM interpolations were not rerun during packaging.** The two representative full-grid reconstructions were run from raw inputs; the other 31 retain their clearly labelled reference results for quick plotting. Complete raw inputs and the full computation path are supplied by `run_all`. Consequently this delivery is not described as a newly completed 33-case end-to-end run.

Fresh full-grid interpolation took about six minutes per tested sparse layout on this machine, excluding other stages. Runtime depends on layout, hardware and storage; allow hours for a full run. Intermediate surfaces and routes are generated locally and are intentionally not shipped as a second large duplicate result archive.

## Rechecking

```matlab
root = setup_project;
addpath(fullfile(root,'validation'));
check_reference_results;  % fits, decisions and coefficient sweep
check_route_times;        % 33 routes, 66 platform–layout comparisons
```

To repeat just the raw-input reconstruction spot checks:

```matlab
step01_calibrate_turning(root);
step02_reconstruct_bathymetry(root,["BCS_M002","PCZ_M001"]);
```

A subset run cannot feed the full response analysis. Run `step02_reconstruct_bathymetry(root)` without a subset before stage 3, or use `run_all`. The subset run and full run share per-case caches when their scientific input and code fingerprints agree.

`checksums_sha256.csv` lists the delivered files and their SHA-256 hashes; it excludes itself. This is a file-integrity inventory, separate from numerical agreement tests.
