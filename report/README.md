# Smart Driving Behaviour Analysis System - LaTeX Major Project Report

This folder contains the complete, academic-grade, modular LaTeX source code for the B.Tech Major Project Report.

## 📁 Directory Structure

```text
report/
├── main.tex                       # Master document (packages, layout, title page, TOC, includes)
├── intro.tex                      # Chapter 1: Introduction (Motivation, Problem Statement, Objectives, Scope)
├── LiteratureReview.tex           # Chapter 2: Literature Review (Telematics, OBD-II vs Phone vs Edge, ML models)
├── RequirementSpecification.tex   # Chapter 3: Requirement Specification (Functional, Non-functional, HW/SW)
├── SystemDesign.tex               # Chapter 4: System Design (4-Tier Arch, DFD L0/L1, Math Models, Schema)
├── SystemImplementation.tex       # Chapter 5: System Implementation (ESP32 C++, BLE, FastAPI, RF/SVM, React HUD)
├── Results.tex                    # Chapter 6: Results & Analysis (Metrics, Confusion Matrix, Score Dist, Potholes)
├── Conclusion.tex                 # Chapter 7: Conclusion & Future Scope (Achievements, Limitations, TinyML/ADAS)
├── reference.tex                  # Bibliography (7 academic citations in ITS / Telematics)
├── README.md                      # Compilation and editing guide
└── figures/                       # Architectural diagrams, confusion matrices, and analysis plots
    ├── system_architecture.png
    ├── dfd_level1.png
    ├── dashboard_preview.png
    ├── confusion_matrix.png
    ├── score_distribution.png
    └── storage_saving.png
```

## 🚀 How to Compile

### Option 1: Overleaf (Recommended)
1. Go to [Overleaf](https://www.overleaf.com).
2. Click **New Project** -> **Upload Project**.
3. Select the [`report.zip`](../report.zip) file generated in the project root.
4. Set the compiler to **pdfLaTeX** and set the main document to `main.tex`.
5. Click **Recompile**.

### Option 2: Local Compilation (Command Line)
Run `pdflatex` twice to resolve the table of contents and internal cross-references:
```bash
cd report
pdflatex main.tex
pdflatex main.tex
```

### Option 3: TeXstudio / VS Code
- Open `report/main.tex` in your LaTeX editor.
- Build with `pdfLaTeX` or `latexmk`.
