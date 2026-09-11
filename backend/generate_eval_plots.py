"""Generate evaluation plots (ROC, PR, Confusion Matrix, Calibration) for each model.

Reads predictions CSVs from output/ and saves PNGs to dashboard/public/evaluation/.
Run once: python generate_eval_plots.py
"""

from pathlib import Path

import matplotlib
matplotlib.use("Agg")  # Non-interactive backend
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import (
    ConfusionMatrixDisplay,
    PrecisionRecallDisplay,
    RocCurveDisplay,
    confusion_matrix,
)
from sklearn.calibration import calibration_curve
from sklearn.preprocessing import label_binarize

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = PROJECT_ROOT / "output"
EVAL_DIR = PROJECT_ROOT / "dashboard" / "public" / "evaluation"
EVAL_DIR.mkdir(parents=True, exist_ok=True)

MODELS = [
    ("logistic_regression", "Logistic Regression"),
    ("random_forest", "Random Forest"),
    ("xgboost", "XGBoost"),
]

CLASSES = ["Critical", "Healthy", "Stressed"]
CLASS_COLORS = {"Critical": "#ef4444", "Healthy": "#22c55e", "Stressed": "#f59e0b"}


def generate_plots(slug: str, display_name: str, df: pd.DataFrame):
    y_true = df["actual_condition"]
    y_pred = df["predicted_condition"]
    prob_cols = ["prob_critical", "prob_healthy", "prob_stressed"]
    y_proba = df[prob_cols].values

    # --- 1. ROC Curves (per class) ---
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    y_bin = label_binarize(y_true, classes=CLASSES)

    for idx, cls in enumerate(CLASSES):
        ax = axes[idx]
        ax.set_title(f"Class: {cls}")
        RocCurveDisplay.from_predictions(
            y_bin[:, idx], y_proba[:, idx], ax=ax, name=display_name,
            color=CLASS_COLORS[cls],
        )
        ax.plot([0, 1], [0, 1], "k--", alpha=0.3)
        ax.set_xlim([0, 1])
        ax.set_ylim([0, 1.05])
    fig.suptitle(f"{display_name} — ROC Curves (One-vs-Rest)", fontsize=14, fontweight="bold")
    fig.tight_layout()
    fig.savefig(EVAL_DIR / f"{slug}_roc_curve.png", dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved {slug}_roc_curve.png")

    # --- 2. Precision-Recall Curves (per class) ---
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    for idx, cls in enumerate(CLASSES):
        ax = axes[idx]
        ax.set_title(f"Class: {cls}")
        PrecisionRecallDisplay.from_predictions(
            y_bin[:, idx], y_proba[:, idx], ax=ax, name=display_name,
            color=CLASS_COLORS[cls],
        )
        ax.set_xlim([0, 1])
        ax.set_ylim([0, 1.05])
    fig.suptitle(f"{display_name} — Precision-Recall Curves", fontsize=14, fontweight="bold")
    fig.tight_layout()
    fig.savefig(EVAL_DIR / f"{slug}_pr_curve.png", dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved {slug}_pr_curve.png")

    # --- 3. Confusion Matrix ---
    fig, ax = plt.subplots(figsize=(7, 6))
    cm = confusion_matrix(y_true, y_pred, labels=CLASSES)
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=CLASSES)
    disp.plot(ax=ax, cmap="Blues", colorbar=False)
    ax.set_title(f"{display_name} — Confusion Matrix", fontsize=13, fontweight="bold")
    fig.tight_layout()
    fig.savefig(EVAL_DIR / f"{slug}_confusion_matrix.png", dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved {slug}_confusion_matrix.png")

    # --- 4. Calibration Curves (per class) ---
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    for idx, cls in enumerate(CLASSES):
        ax = axes[idx]
        ax.set_title(f"Class: {cls}")
        prob_true, prob_pred = calibration_curve(y_bin[:, idx], y_proba[:, idx], n_bins=10)
        ax.plot(prob_pred, prob_true, "s-", color=CLASS_COLORS[cls], label=display_name)
        ax.plot([0, 1], [0, 1], "k--", alpha=0.3, label="Perfectly calibrated")
        ax.set_xlabel("Mean predicted probability")
        ax.set_ylabel("Fraction of positives")
        ax.set_xlim([0, 1])
        ax.set_ylim([0, 1.05])
        ax.legend(loc="lower right", fontsize=8)
    fig.suptitle(f"{display_name} — Calibration Curves", fontsize=14, fontweight="bold")
    fig.tight_layout()
    fig.savefig(EVAL_DIR / f"{slug}_calibration_curve.png", dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved {slug}_calibration_curve.png")


def main():
    print(f"Output dir: {OUTPUT_DIR}")
    print(f"Eval dir:   {EVAL_DIR}")
    print()

    for slug, display_name in MODELS:
        pred_csv = OUTPUT_DIR / f"{slug}_predictions.csv"
        if not pred_csv.exists():
            print(f"Skipping {display_name}: {pred_csv} not found")
            continue

        print(f"Generating plots for {display_name}...")
        df = pd.read_csv(pred_csv)
        generate_plots(slug, display_name, df)
        print()

    print("Done! Evaluation images saved to:", EVAL_DIR)


if __name__ == "__main__":
    main()
