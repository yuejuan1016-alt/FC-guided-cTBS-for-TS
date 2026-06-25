# rTMS Connectivity-vs-Scalp RCT Analysis README

This repository contains code and figure source data associated with the manuscript:

**Brain Biomarkers for Predicting Response to Individualized Stimulation in Pediatric Tourette Syndrome**

## Repository Layout

```text
├── code
│   ├── FCguidedTMS_Runcode_YJ
│   │   └── FCguidedTMS_Runcode_YJ
│   │       ├── Code
│   │       ├── Readme
│   │       │   ├── README_EN.md
│   │       └── mask
│   ├── LASSO
│   └── LMM
└── data
    ├── Figure3a/Figure 3a.xlsx
    ├── Figure3b/Figure 3b.xlsx
    ├── Figure4a/Figure 4a.xlsx
    ├── Figure4b/Figure 4b.xlsx
    ├── Figure4c/Figure 4c.xlsx
    ├── Figure4d/Figure 4d.xlsx
    ├── Figure5a/Figure 5a.xlsx
    └── Figure5b/Figure 5b.xlsx
```

## Study and Analysis Overview

The study is a double-blind randomized controlled trial comparing:

- **Functional connectivity-guided cTBS** targeting the left SMA voxel with peak functional connectivity to the left GPi.
- **Scalp-based cTBS** targeting 15% of the nasion-to-inion distance anterior to Cz along the sagittal midline.

Main outcomes:

- Clinical response: YGTSS total score change over baseline, week 1, week 2, and week 4.
- Neuroimaging outcomes: GPi-SMA functional connectivity, ALFF at the stimulation target, and ALFF in the left GPi.
- Predictive modeling: baseline rs-fMRI features used to predict YGTSS response using LASSO.

## Minimal Software Requirements

### MATLAB

- SPM12 (https://www.fil.ion.ucl.ac.uk/spm/).
- DPABI/DPARSFA (http://rfmri.org/dpabi).
- MATLAB 2021a or compatible.
- Statistics and Machine Learning Toolbox for `lasso`.


### SPSS

- IBM SPSS Statistics with MIXED procedure support.

### Neuroimaging resources

- DISTAL atlas and AAL toolkit.
- BrainSight for neuronavigation export/use.


## FC-Guided Target Localization Workflow

For the FC-guided group, the manuscript describes individualized target localization from pretreatment rs-fMRI:

1. Use the left GPi as the seed region, defined from the DISTAL atlas.
2. Transform the GPi mask from standard space to each participant's native space.
3. Use the left SMA as the allowed cortical stimulation target region, defined from the AAL template.
4. Transform the SMA/stimulation mask into native space.
5. Compute seed-based Pearson functional connectivity between the left GPi and voxels within the left SMA mask.
6. Select the voxel with the strongest FC as the stimulation target, with manuscript criteria:
   - FC threshold > 0.2.
   - Located within 4 cm beneath the scalp.
7. Send the final target coordinate to BrainSight for neuronavigation.

Repository support:

- `code/FCguidedTMS_Runcode_YJ/FCguidedTMS_Runcode_YJ/Code/RunCode.m` implements a single-subject workflow for preprocessing, native-space mask transformation, target/effective-region ROI creation, and FC calculation through DPARSFA.
- `mask/Left_M1.nii` is the available stimulation mask in this repository. 
- `RunCode.m` creates a spherical ROI using the `radius` parameter,. 

## fMRI Outcome Calculation

### Functional Connectivity and ALFF (calculated by DPABI)

## Statistical Analysis Workflow

The manuscript describes the following statistical analyses:

1. Baseline demographics and clinical characteristics.
2. Clinical longitudinal LMM for YGTSS and CGI outcomes.
3. Neuroimaging longitudinal LMM for FC, ALFF at stimulation target, and ALFF in left GPi.
4. Pearson correlation between change in GPi-SMA FC and change in YGTSS.
5. Permutation test for between-group response variability.
6. LASSO with leave-one-out cross-validation for baseline imaging predictors.
7. Predictor performance assessed by Pearson r and MSE between cross-validated predicted and actual YGTSS reduction, with permutation testing.

The current repository only contains scripts for selected parts of these analyses:

- LMM syntax for clinical YGTSS: `code/LMM/YGTSS_LMM.sps`.
- LMM syntax for neuroimaging outcomes: `code/LMM/TableS2_LMM_Syntax_ASCII.sps`.
- LASSO MATLAB script: `code/LASSO/lasso_figure_4para.m`.

