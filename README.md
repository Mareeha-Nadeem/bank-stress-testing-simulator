# Bank Stress-Testing Simulator

A data-driven simulator that answers one question for a Pakistani bank facing a macroeconomic shock: will it stay Healthy, become Stressed, or turn Critical.

## Overview

Pakistani banks are exposed to macroeconomic shocks such as inflation spikes, interest rate hikes, currency devaluation, and GDP contractions, but there is no accessible, data-driven way to see how a given shock would actually affect a bank's capital adequacy (CAR), asset quality (NPL), liquidity, and profitability. Regulators and analysts are left with two options: a manual, bank-by-bank stress test, which is slow and inconsistent across analysts, or no tool at all for quickly asking "what happens to bank health if X shock hits."

This project builds a system to answer that question directly. It learns sector-level default risk from real loan data, applies that risk to 40 synthetic but realistic Pakistani banks, tests each bank against 500 macroeconomic shock scenarios, and produces a final health label: Healthy, Stressed, or Critical: for every bank and scenario combination. Predictions are served through a FastAPI backend, visualized in a Next.js dashboard, and paired with an LLM-generated explanation of each result.

## Architecture

```
Data (raw > processed) > Modeling (notebooks) > models/*.pkl
                                                       │
                                                       v
                                          FastAPI backend (backend/)
                                                       │
                                                       v
                                        Next.js dashboard (dashboard/)
```

- **Modeling pipeline**: cleans raw data, engineers features, trains and evaluates Logistic Regression, Random Forest, and XGBoost classifiers.
- **Backend (FastAPI)**: serves predictions from the trained models and generates natural-language recommendations via an LLM.
- **Dashboard (Next.js)**: lets users run simulations, browse banks and scenarios, compare model performance, and view generated reports.

## Project structure

```
bank-stress-testing-simulator/
├── backend/                        # FastAPI app
│   ├── main.py                     # API entrypoint (/recommend, etc.)
│   ├── requirements.txt
│   └── .env                        # LLM config (not committed)
├── dashboard/                      # Next.js frontend
│   ├── public/
│   │   └── evaluation/             # model evaluation plots (ROC, PR, confusion matrix, calibration)
│   └── src/
│       ├── app/                    # pages: banks, model-performance, reports, scenarios, simulator
│       ├── components/             # UI components (shadcn/ui-based)
│       └── lib/                    # API client, utilities
├── modeling/                       # model training & evaluation notebooks
│   ├── 01_logistic_regression.ipynb
│   ├── 02_random_forest.ipynb
│   ├── 03_xgboost.ipynb
│   ├── 04_model_comparison.ipynb
│   └── 05_model_evaluation.ipynb
├── notebooks/                      # data cleaning & EDA notebooks
│   ├── data_cleaning.ipynb
│   ├── eda_bank_profiles.ipynb
│   ├── eda_bank_stress_panel.ipynb
│   ├── eda_loan_portfolio.ipynb
│   ├── eda_macro_scenarios.ipynb
│   ├── eda_macro_stress_scenarios.ipynb
│   └── feature_engineering.ipynb
├── models/                         # trained model artifacts (gitignored: see note below)
│   ├── linear_regression_model.pkl
│   ├── random_forest_model.pkl
│   └── xgboost_model.pkl
├── output/                         # per-model metrics & predictions (CSV)
├── evaluation/                     # aggregate evaluation plots
├── processed/                      # cleaned data
├── raw/                            # original data
├── Schema/                         # SQL schema & EDA queries
├── .env.example
└── README.md
```

## Models

`models/` holds the trained model artifacts, generated locally by the `modeling/` notebooks and not version-controlled: `random_forest_model.pkl` is roughly 145 MB, which exceeds GitHub's 100 MB file-size limit, so it is gitignored (see `.gitignore`). To regenerate a model, run the corresponding notebook in `modeling/`: e.g. `02_random_forest.ipynb` trains the random forest pipeline and saves it to `models/random_forest_model.pkl` with `joblib.dump`.

> **Version note:** models must be loaded with the same scikit-learn version they were trained with: pickled models are not guaranteed to be compatible across scikit-learn versions. Pin the version in `backend/requirements.txt` if you retrain against a different environment.

## Data description

| File | Grain | Rows (cleaned) | Key columns | Notes |
|---|---|---|---|---|
| `bank_profiles.csv` | one row per bank | 40 | `bank_id`, `size_tier`, `total_assets_usd`, `total_loans_usd`, `deposit_base_usd`, `baseline_car_pct`, `baseline_liquidity_ratio_pct`, `baseline_roa_pct`, `sector_concentration`, `bank_risk_factor`, ten `sector_wt_*` columns | Sector weights sum to roughly 1.0 per bank |
| `loan_portfolio.csv` | one row per loan | ~3,000 | `loan_id`, `sector`, `pd_annual`, `lgd`, `ead`, `rwa`, `loan_amount` | Loan-level basis the sector risk profiles are learned from |
| `macro_scenarios.csv` | one row per scenario | 500 | `scenario_id`, `stress_intensity`, `scenario_severity`, `gdp_shock_pp`, `unemp_shock_pp`, `rate_shock_pp`, `credit_spread_bps`, `inflation_shock_pp`, `fx_devaluation_pct` | `scenario_severity` runs baseline to severe |
| `macro_stress_scenarios.csv` | one row per scenario x sector | 60 (6 scenarios x 10 sectors) | `scenario`, `sector`, `pd_multiplier`, `base_lgd`, `stressed_lgd`, plus the same shock columns as above | Includes `gfc_like` and `covid_like`, which are not in `macro_scenarios.csv` and are not tested in the main run: see caveat below |
| `bank_stress_simulated_panel.csv` | one row per bank x scenario | ~20,000 (40 banks x ~500 scenarios) | `bank_id`, `scenario_id`, shock inputs, `projected_npl_ratio_pct`, `car_after_pct`, `liquidity_after_pct`, `roa_after_pct`, `bank_condition` | Main output of the simulation; `bank_condition` is Healthy, Stressed, or Critical |

**Known caveats**

- The `gfc_like` / `covid_like` gap described above: results in the panel do not cover those named historical scenarios.
- A handful of rows across the panel and the loan portfolio had to be corrected rather than simply dropped, most notably a decimal-point-shift error in `roa_after_pct` and a `-1` sentinel value standing in for missing data in `liquidity_after_pct`. See `eda_bank_stress_panel.ipynb` for detail.
- All data here is synthetic. It is built to resemble real-world Pakistani bank data and deliberately includes realistic data-quality issues, but it is not drawn from actual bank filings.

## Methodology / approach

1. **EDA.** Each raw file gets its own notebook that inspects structure, quantifies every data-quality issue found, and plots the main distributions and relationships, with a short conclusion after each step.
2. **Cleaning.** Each raw file had its own mix of problems: inconsistent category spelling, numbers stored as text with currency symbols, percent signs, or thousand separators, missing values, a few sentinel values standing in for missing data, exact duplicate rows, and one identified unit-scale error. `data_cleaning.ipynb` fixes all of these and writes a clean version of each file to `processed/`, without altering the raw files.
3. **Feature engineering.** `feature_engineering.ipynb` derives the model-ready feature set (`bank_health_features.csv`) from the cleaned panel.
4. **Modeling.** Logistic Regression, Random Forest, and XGBoost classifiers are trained and compared in `modeling/`, with per-model metrics and predictions saved to `output/` and evaluation plots saved to `evaluation/`.

## Results / key findings

- Across all 40 banks and roughly 500 scenarios, banks end up Healthy in about 52% of bank-scenario pairs, Stressed in about 33%, and Critical in about 16%.
- The Healthy share falls steadily as scenario severity increases: about 74% Healthy at baseline versus about 30% Healthy under severe scenarios, with Critical outcomes rising from about 8% to about 26% over the same range. This is the expected direction for a stress test and is a useful sanity check that the underlying simulation behaves sensibly.
- Loan-level PD and the macro stress file's PD multipliers agree with each other on which sectors are riskier: cyclical sectors such as energy and real estate carry higher risk under stress than steadier sectors such as utilities and consumer.
- Shock variables move together the way a real macro shock would: GDP shocks are mostly negative, GDP and unemployment shocks move in opposite directions, and credit spreads and rate shocks widen as scenario severity increases.

## Getting started

### Prerequisites

- Python 3.11+ (see version note above regarding scikit-learn compatibility)
- Node.js 18+ and npm
- An LLM API key (used by the backend to generate recommendation text)

### 1. Backend setup

```bash
cd backend
pip install -r requirements.txt
```

Create a `.env` file in `backend/` using `.env.example` as a template, and fill in your LLM credentials:

```dotenv
# ── LLM API Configuration ──────────────────────────────────────────────────
# Change these values to update the API key / endpoint.

LLM_API_KEY=
LLM_BASE_URL=
LLM_MODEL=
```

Run the API server:

```bash
uvicorn main:app --reload
```

The backend runs at `http://localhost:8000` by default. Interactive API docs are available at `http://localhost:8000/docs`.

### 2. Dashboard setup

```bash
cd dashboard
npm install
npm run dev
```

The dashboard runs at `http://localhost:3000` and expects the backend to be running at `http://localhost:8000`.

### 3. Verify

With both servers running, open `http://localhost:3000`, select a model in the Simulator, and run a prediction to confirm the dashboard and backend are connected end to end.

## Tech stack

| Layer | Technology |
|---|---|
| Data & modeling | Python, pandas, scikit-learn, XGBoost, Jupyter |
| Backend API | FastAPI, uvicorn |
| Recommendation engine | LLM (OpenAI-compatible API) |
| Frontend | Next.js, TypeScript, Tailwind CSS, shadcn/ui |