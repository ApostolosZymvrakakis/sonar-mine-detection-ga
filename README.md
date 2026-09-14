# AI-Driven Sonar Mine Detection for Underwater Drones in Naval Mine Countermeasures

Code accompanying the MSc Artificial Intelligence dissertation of the same
title (University of Plymouth, PROJ518, September 2026).

Genetic-algorithm optimisation of YOLOv5s training hyperparameters for
mine detection in side-scan sonar, evaluated under a documented,
group-aware protocol. The headline results are a +24.2% mean improvement
in cross-validated mAP@0.5 over 41 of 44 paired folds, and a measurement
that changing **only** the granularity of the train/test split moves
measured mAP@0.5 from 0.507 to 0.735.

## Data

The primary dataset is **not** redistributed here. It is the public
Santos SSS release:

> Pessanha Santos, N., Moura, R., Sampaio Torgal, G., Lobo, V. and
> de Castro Neto, M. (2024) 'Side-scan sonar imaging data of underwater
> vehicles for mine detection', *Data in Brief*, 53, 110132.
> doi:10.1016/j.dib.2024.110132

1,170 images, two classes (MILCO, NOMBO), 74% of images background-only.

## Contents

| File | What it does |
|---|---|
| `01_data_preparation_and_ga_search.ipynb` | Offline geometric augmentation (×4), group index, group-aware stratified split, and the 7-gene search: chromosome encoding, tournament selection, single-point crossover, Gaussian mutation, elitism, fitness cache. Deterministic under seed 42. |
| `02_cross_validation.ipynb` | The 44 paired folds, baseline vs GA-optimised, 40 epochs each. Produces `cv_results.csv`. |
| `03_final_models_and_holdout.ipynb` | The 100-epoch final models and the single locked hold-out evaluation of each. |
| `04_predictions_and_comparison.ipynb` | Matched baseline re-run, the prediction-level contingency table, and Figure 4.6. |
| `analysis_paired_tests.py` | Reproduces Tables 4.2 and 4.3 from `cv_results.csv`. |
| `figures_dissertation.R` | The ggplot2 script producing the six R figures of the dissertation. |
| `make_split_manifest.ipynb` | Regenerates `holdout_groups.txt` from the dataset. |
| `cv_results.csv` | The raw 44-fold record: one row per fold per configuration. |
| `santos_metadata.csv` | Per-image and per-annotation metadata (year, class, box width/height as % of image). Source of Figure 4.1. |
| `holdout_groups.txt` | The 117 group identifiers of the locked hold-out set. |
| `curves_FINAL_baseline.csv` | Per-epoch training record of the final baseline model. |
| `curves_FINAL_ga.csv` | Per-epoch training record of the final GA-optimised model. |

The four notebooks are Colab notebooks and expect the dataset as `santos_sss.zip`
in Google Drive. They are self-contained: each rebuilds the augmented dataset and
the split from the published data, because a Colab session starts with an empty
disk. Since every draw is seeded at 42 and made over group names, the rebuild is
the same dataset every time, which is what allows runs from separate sessions to
be joined.

An earlier exploratory search over twelve genes, including augmentation genes, was
run before the protocol of Section 3.5 was settled. It is not part of the reported
work and is not included here; the search described in the dissertation is the
7-gene search in `01_data_preparation_and_ga_search.ipynb`.

## Reproducing the reported statistics

```bash
python3 analysis_paired_tests.py cv_results.csv
```

prints Table 4.2, Table 4.3, the three folds the baseline won, and the
strict-IoU sub-sample. Requires `pandas`, `numpy`, `scipy`.

## Reproducing the figures

```bash
Rscript figures_dissertation.R
```

reads `cv_results.csv`, `curves_FINAL_baseline.csv`, `curves_FINAL_ga.csv` and
`santos_metadata.csv` from the working directory, writes five figures to
`figures/` and `santos_eda_plots.png` beside the script. Requires `ggplot2`.

## Reproducing the split

Run `make_split_manifest.ipynb`. It writes `holdout_groups.txt`. The draw
is over group names under `random.Random(42)`, stratified by annotation
content, so it reproduces the same 117 groups on any machine from the
published dataset alone.

## What reproduces and what does not

**Data preparation is deterministic.** The augmentation, the hold-out
split and the fold assignment are seeded at 42 and reproduce exactly.

**Training runs are not seeded.** No seed was passed to the YOLOv5
training script, so a repeated experiment reproduces only to within
run-to-run variance, measured for the champion on the hold-out at
**0.006 mAP@0.5**.

**Albumentations version matters.** Its affine transform API changed
between major releases; the augmented images will differ slightly under a
different version. Pin versions from the outset. The environment recorded
at the time of writing is Python 3.12.13, PyTorch 2.11.0, NumPy 2.0.2,
pandas 2.2.3, scikit-learn 1.6.1, Albumentations 2.0.8.

## Why the manifest is published

Section 5.3 of the dissertation argues that absolute detection metrics in
the sonar literature are not comparable because evaluation protocols are
undocumented, and Section 6.3 recommends that split manifests and seeds be
published. `holdout_groups.txt` is that recommendation applied to this
work: a protocol described in prose can still be misread, a manifest
cannot.

## Author

Apostolos Zymvrakakis — Student ID 25126736

MSc Artificial Intelligence, University of Plymouth

Supervisor: Dr Vassilis Cutsuridis
