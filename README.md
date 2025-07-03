# Kymomatic_Temple

## ✨ About the Temple

Temple aims to integrate multiple tools for image and specctroscopy data.

- `LauncherTemple.m` — main entry point with visuals and transitions

# 🧿 Kymomatic Scibyl
*Kymomatic Scibyl* is one of several components in the **Temple Launcher**, a mystical user interface for analytical modules. From foggy gates to oracle selection, the Temple guides researchers into arcane data territories.
**Modular wizard for slope-change analysis on time-series profiles.**  
Part of the *Kymomatic Temple* ecosystem.

---

## 🧰 What is Kymomatic Scibyl?

Kymomatic Scibyl is a step-by-step tool designed to analyze paired (Time, Height) profiles and detect significant slope transitions using advanced signal processing techniques.

🔍 Inspired by pattern recognition and crafted for interpretability and automation.

---

## ⚙️ Features

- 💠 Automatic detection of events across multiple profiles
- 🧹 Savitzky–Golay smoothing and interactive configuration
- 🧠 Detection methods:
  - First & Second Derivatives
  - Wavelet Transform
  - Clustering
  - Kalman Filtering
  - Spline Regression
- 📊 Visual summary with scatterplots and slope-change boxplots
- 📤 Export to `.xlsx` files: detected points and slope deltas

---

## 🚀 Getting Started

1. Open `KymomaticScibyl.m` in MATLAB.
2. Run it. A wizard GUI will appear.
3. Select your `.csv` file with paired `(Time, Height)` columns.
4. Follow the steps to configure smoothing, tune detection, and review results.
5. Export results from the final window.

---

## 🛠️ Data Format

The input file must:

- Be a `.csv` file with **even number of columns**.
- Each pair of columns represents one profile:
  - First column: Time  
  - Second column: Height

✔️ Example:  
`Time1, Height1, Time2, Height2, ..., TimeN, HeightN`

---

# Arcane Clustering 🔬✨  
*Reveal the hidden structures behind experimental profiles*

## Overview

**Arcane Clustering** is a MATLAB-based graphical interface designed to assist scientists and analysts in exploring, smoothing, and clustering profile-based data. Inspired by Gothic cloisters and analytical mysticism, it provides a visually immersive workspace for classifying profile curves using slope segmentation and unsupervised clustering.

---

## Features

- 📄 Load experimental data from `.xlsx` or `.csv` files  
- 🗂️ Navigate seamlessly across samples (each sheet = one sample)  
- 🌿 Apply optional smoothing with user-defined parameters  
- 📈 Extract slope features using segmented linear regression  
- 🔍 Perform automatic or manual clustering (K-Means + silhouette scoring)  
- 📊 Visualize boxplots by segment or by cluster  
- 💾 Export annotated slope tables, smoothed curves by group, and cluster maps  
- 🎨 Themed interface with stained glass motif and botanical detailing  
- 🔔 Optional audio cues and welcome animation

---

## File Structure (Exported Results)

Upon saving, you may choose to export:

| Sheet Name       | Description                                                  |
|------------------|--------------------------------------------------------------|
| `Slopes`         | Table of slopes for each curve and segment (`Stiffness_i-j`) |
| `GroupedCurves`  | Smoothed profiles arranged by detected cluster               |
| `ClusterMap`     | Mapping of profile index to cluster assignment               |

---

## Input Format

The tool expects datasets with paired `[X Y]` columns:

````[X1 Y1]  [X2 Y2]  [X3 Y3]  ...````  


💡 Typical Workflow
- Run ArcaneClustering in MATLAB
- Choose a .xlsx file where each sheet holds a sample (columns must be [X Y] pairs)
- Navigate between sheets using the arrow buttons
- Apply smoothing and preview profiles using Refresh
- Detect group patterns with Autocluster
- Save outputs using Save and choose what to export



⚠️ Requirements
- MATLAB R2021a or newer (recommended)
- Excel file with profile data structured in [X1 Y1], [X2 Y2], ... pairs
- Audio files: splash_tone.wav and bell.wav for ambiance
- Background image stained_glass.png depicting the themed window


📚 Philosophy
Arcane Clustering is more than a tool — it's a symbolic space where science meets myth. Each curve is a manuscript, each cluster a monastic order of hidden behavior. Like light through glass, knowledge only reveals itself if you invite it to shine.

## 📖 License & Credits

Developed by **[Mike Kantus](https://github.com/MikeKantus)**  
With architectural assistance from *Hermes*, your faithful AI artisan.  
MIT License.

