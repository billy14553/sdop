# Sparse Dynamic Orthogonal Projection (SDOP) for Interpretable Calibration Transfer

MATLAB implementation for the paper **"Toward Interpretable Calibration Transfer: A Sparse Modeling Approach Integrated with Dynamic Orthogonal Projection"**.

This repository provides code to explore **which wavelength bands are important** in spectroscopic model transfer and **why they matter**, bridging the gap between calibration transfer performance and model interpretability.

---

## Overview

Calibration transfer is essential in chemometrics when a predictive model trained on one instrument (source domain) needs to work on another (target domain). Traditional methods such as Dynamic Orthogonal Projection (DOP) effectively remove domain-specific variation but lack interpretability — it remains unclear which spectral regions contribute to robust transfer.

This work introduces **Sparse Dynamic Orthogonal Projection (SDOP)**, which integrates:
- **Dynamic Orthogonal Projection (DOP)** for domain-invariant feature extraction
- **Sparse Partial Least Squares (Sparse PLS)** for wavelength selection

By enforcing sparsity on the regression coefficients in the DOP-corrected latent space, SDOP identifies compact, physically meaningful wavelength regions that are both **predictive** and **transferable**.

---

## Repository Structure

| File | Description |
|------|-------------|
| `scripts6.m` | **Main script** to reproduce the primary results of the paper. Evaluates PLS, DOP, and SDOP across multiple source–target scenarios with visualization. |
| `scripts6_comparison.m` | Extended comparison script. Benchmarks SDOP against other variable selection methods (LASSO, CovSel, CARS) within the DOP framework using LOO cross-validation and the 1-SE rule. |
| `compareVariableSelection.m` | Standalone visualization tool to compare selected variables across methods (LASSO, CovSel, CARS, SDOP). |
| `dop2.m` | Core DOP implementation. Computes the orthogonal projection matrix `E` via Gaussian-kernel-based virtual sample generation and SVD-based subspace removal. |
| `sparsepls1.m` | Sparse PLS regression engine. Performs iterative soft-thresholding to select a fixed number of variables per latent variable. |
| `CrossValidate_DOP.m` | K-fold cross-validation for DOP parameter optimization (variance threshold `Vd` and number of latent variables). |
| `loadData.m` | Loads experimental datasets (`corn.mat`, `nir_data.mat`). |
| `calculate_metrics.m` | Computes RMSEP and R² for model evaluation. |
| `compute_aij.m` | Gaussian kernel weight computation for virtual standard sample generation. |
| `svd_reconstruction.m` | Determines the number of significant components based on cumulative explained variance. |
| `duplex.m` | Duplex algorithm for representative train/test splitting. |
| `savgol.m` | Savitzky–Golay smoothing filter for spectral preprocessing. |
| `covsel.m` | Covariance maximization variable selection. |
| `carspls.m` / `carsplslda.m` | Competitive Adaptive Reweighted Sampling (CARS) for variable selection. |
| `calculateExplainedVariance.m` | Explained variance calculation for model diagnostics. |
| `calculatePLS_VIP.m` / `pls_vip.m` | Variable Importance in Projection (VIP) score computation. |
| `SCIPlot.m` | Publication-quality figure styling utility. |
| `corn.mat` | Corn NIR dataset (instruments: mp5, m5, mp6; wavelength 1100–2498 nm). |
| `nir_data.mat` | Additional NIR dataset (instruments: spec1, spec2; wavelength 800–1400 nm). |

---

## Quick Start

### Requirements

- MATLAB (R2019b or later recommended)
- Statistics and Machine Learning Toolbox (for `plsregress`, `lasso`, `crossvalind`)

### Reproduce Main Results

Open MATLAB, navigate to the repository folder, and run:

```matlab
scripts6
```

This script will:
1. Load source and target domain spectral data.
2. Preprocess spectra with Savitzky–Golay smoothing and Duplex splitting.
3. Compute the DOP projection matrix `E` for each source–target pair.
4. Train and evaluate **PLS**, **DOP**, and **SDOP** models.
5. Generate figures including:
   - Cross-validated R² vs. number of latent variables
   - Regression coefficient profiles (`β_DOP` vs. `β_SDOP`)
   - Mean spectra before and after DOP correction
   - Sparsity–performance trade-off curves

### Run Extended Comparisons

To compare SDOP with LASSO, CovSel, and CARS under the DOP framework:

```matlab
scripts6_comparison
```

Results are automatically saved as `.mat` files and visualized as PNG figures.

---

## Methodology

### 1. Dynamic Orthogonal Projection (DOP)

Given source domain data `(Xs, Ys)` and target domain data `(Xt, Yt)`:

1. **Virtual standard samples** are synthesized from the source domain via Gaussian kernel weighting conditioned on target domain responses.
2. The difference matrix `D = X̂_tar − X_tar` is decomposed via SVD.
3. The orthogonal projection matrix is constructed as:

   ```
   E = I − VVᵀ
   ```

   where `V` spans the domain-specific variation subspace.

4. Source spectra are projected into the invariant space: `X* = Xs · E`.

### 2. Sparse PLS (SDOP)

After DOP correction, Sparse PLS regression is applied on `X*`:

- For each latent variable, only the top `nvarX` variables (by absolute weight) are retained.
- Soft thresholding zeroes out minor coefficients, yielding a sparse regression vector `β_SDOP`.
- The resulting model uses only a small subset of wavelengths while maintaining (or improving) predictive accuracy on the target domain.

### 3. Evaluation Metrics

- **RMSEP**: Root Mean Square Error of Prediction
- **R²p**: Coefficient of determination on the test set
- **Sparsity**: Proportion of zero coefficients in the regression vector

---

## Datasets

| Dataset | Instruments | Wavelength Range | Features |
|---------|-------------|------------------|----------|
| Corn    | mp5 ↔ m5 ↔ mp6 | 1100–2498 nm | 700 |
| NIR     | spec1 ↔ spec2  | 800–1400 nm  | 301 |

Each dataset supports multiple transfer directions (e.g., mp5 → m5, mp5 → mp6, spec1 → spec2).

---

## Key Scripts at a Glance

```
scripts6.m                  → Main paper results (PLS / DOP / SDOP)
scripts6_comparison.m       → Benchmark vs. LASSO, CovSel, CARS
compareVariableSelection.m  → Visual comparison of selected wavelengths
dop2.m                      → DOP projection matrix computation
sparsepls1.m                → Sparse PLS engine
CrossValidate_DOP.m         → CV for DOP hyperparameter selection
```

---

## Citation

If you use this code in your research, please cite:

```bibtex
@article{sdop2026,
  title={Toward Interpretable Calibration Transfer: A Sparse Modeling Approach Integrated with Dynamic Orthogonal Projection},
  journal={...},
  year={2026},
  publisher={...}
}
```

---

## License

This project is released for academic and research purposes. Please refer to the repository license for details.

---

## Contact

For questions or issues regarding the code, please open an issue on GitHub.
