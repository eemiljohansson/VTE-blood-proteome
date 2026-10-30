# The Blood Proteome in Venous Thromboembolism

![Static Badge](https://img.shields.io/badge/Language-%23276DC3?style=for-the-badge&logo=R&logoColor=black&labelColor=white)
![Static Badge](https://img.shields.io/badge/Apache--2.0_license-yellow?style=for-the-badge)

## Table of Contents

1. [Project overview](#project-overview)
2. [Data description](#data-description)
3. [Methodology](#methodology)
4. [Usage](#usage)
5. [Directory structure](#directory-structure)
6. [Results & insights](#results--insights)
7. [License](#license)
8. [Contact](#contact)

## Project Overview

This repository contains the code to recreate the figures in the manuscript: **The Blood Proteome in Venous Thromboembolism** by Johansson E et al. (2027).

The goal is to characterize the blood plasma proteome in both acute and post-venous thromboembolism (VTE) patients from various disease groups.

The repository includes scripts for data exploration, differential abundance analysis, machine learning, and visualization of the results.

## Data Description

This study is based on plasma proteome profiles from over 6,000 individuals, encompassing both healthy individuals and patients across a wide spectrum of diseases. This work is associated with the human pan-disease blood atlas, published in Science (2025) by Álvez MB et al. (https://www.science.org/doi/10.1126/science.adx2678).

- **Cohort composition**: the VTE samples, part of Venous thromboEmbolism BIOmarker Study (VEBIOS), were collected at the Karolinska hospital in Stockholm, Sweden. Comparison groups include cross-sectional disease cohorts (Human Disease Blood Atlas).
- **Proteomic platform**: protein profiling was performed using the Olink Explore 1536 platform, which utilizes the Proximity Extension Assay (PEA) technology. A high-throughput, antibody-based method that enables simultaneous quantification of thousands of proteins from minimal plasma volumes.

The analysis employed a combination of univariate techniques to uncover key VTE-related protein patterns. Key components include:

- **Differential abundance analysis**: applied to all measured proteins to identify significant changes in abundance of VTE compared to comparison groups.
- **Feature selection by machine learning**: Combining results from regularized regression models (Least Absolute Shrinkage and Selection Operator (LASSO), Elastic Net, and Ridge regression) and Random Forest.
- **Compact protein-panel selection**: Combining LASSO and Ridge regression to identify a minimal set of proteins that can accurately classify VTE from other disease groups.

## Results & insights

Several key insights were derived from the analysis of the dataset:

- **Insights from a pan-disease perspective**: Several blood plasma proteins remains statistically significant and important across comparisons in acute and post-treatment VTE.
- **Biological interpretation of VTE-specific markers**: The identified proteins are involved in pathways related to complemented system, coagulation cascades, and fibrin, which are critical in the pathophysiology of VTE.

## Usage

To explore the code used for the analysis described in the manuscript:

1. Clone this repository:
   ```bash
   git clone https://github.com/eemiljohansson/VTE-blood-proteome.git
   ```
2. Install R dependencies using renv:
   ```R
   renv::restore()
   ```

## Folder structure

Folder structure:
- `data/` — example datasets  
- `scripts/` — quarto notebooks for generating figures and tables  
- `scripts/functions/` — R scripts for data processing and exploration  
- `plots/` — output figures from analyses  
- `tables/` — output tables from analyses 

```bash
📁 Thrombosis-profiling/
├── 📂 scripts/                 # Core analysis scripts (Quarto)
│   ├── 01_data_exploration.qmd         # Exploring the data 
│   ├── 02_differential_analysis.qmd    # Comparing VTE cohorts to comparison groups
│   ├── 03_feature_selection.qmd        # Feature selection by machine learning
│   ├── 04_compact_protein_panel.qmd    # Creation of compact machine learning models for VTE classification
│   └── 📂 functions/          # Helper functions for data processing and analysis
├── 📂 plots/                  # Output figures from analyses
├── 📂 tables/                 # Output tables from analyses
├── 📄 README.md               # Overview of the project
└── 📜 LICENSE                 # License file
```

## License
This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Contact Information

For questions or inquiries, please contact:

Emil Johansson
GitHub: [eemiljohansson](https://github.com/eemiljohansson)
Email: emil.johansson@scilifelab.se
