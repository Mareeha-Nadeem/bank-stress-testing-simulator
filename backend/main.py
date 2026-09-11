"""FastAPI backend for Bank Stress Testing Simulator dashboard."""

import json
import os
from pathlib import Path
from typing import Literal

import joblib
import numpy as np
import pandas as pd
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

# Load LLM config from backend/.env
load_dotenv(Path(__file__).resolve().parent / ".env")

# Paths
PROJECT_ROOT = Path(__file__).resolve().parent.parent
MODELS_DIR = PROJECT_ROOT / "models"
OUTPUT_DIR = PROJECT_ROOT / "output"
REPORTS_DIR = PROJECT_ROOT / "outputs"

# Class label order from trained models: ['Critical', 'Healthy', 'Stressed']
CLASS_ORDER = ["Critical", "Healthy", "Stressed"]
CLASS_INDEX = {c: i for i, c in enumerate(CLASS_ORDER)}

# 12 raw features + 2 server-side interaction terms (see /predict)
N_FEATURES = 14

# ---------------------------------------------------------------------------
# App + CORS
# ---------------------------------------------------------------------------
app = FastAPI(title="Bank Stress Test API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Load models on startup
# ---------------------------------------------------------------------------
_models: dict = {}
_model_errors: dict = {}  # model name -> reason it cannot serve predictions


@app.on_event("startup")
def load_models():
    import warnings

    import sklearn
    from sklearn.exceptions import InconsistentVersionWarning

    def _load(path):
        """Load a pickled model and capture the sklearn version it was fitted with."""
        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter("always", InconsistentVersionWarning)
            model = joblib.load(path)
        for w in caught:
            if issubclass(w.category, InconsistentVersionWarning):
                return model, getattr(w.message, "original_sklearn_version", None)
        return model, None

    model_paths = {
        "logistic_regression": MODELS_DIR / "linear_regression_model.pkl",
        "random_forest": MODELS_DIR / "random_forest_model.pkl",
    }
    for name, path in model_paths.items():
        if not path.exists():
            continue
        model, trained_with = _load(path)
        _models[name] = model

        # Smoke-test each model: scikit-learn pickles only work under the
        # version they were trained with, so surface that problem at startup
        # instead of crashing with a confusing 500 on the first /predict.
        try:
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                probe = np.zeros((1, N_FEATURES))
                model.predict(probe)
                model.predict_proba(probe)
        except Exception as exc:
            fix = (
                f"pip install scikit-learn=={trained_with}"
                if trained_with
                else "re-fit the models under the installed scikit-learn version"
            )
            reason = (
                f"Model '{name}' was fitted with scikit-learn "
                f"{trained_with or 'an unknown version'} but this server runs "
                f"scikit-learn {sklearn.__version__}; scikit-learn pickles are "
                f"not compatible across versions (error: {exc!r}). Fix: run "
                f"the backend with the interpreter the models were trained "
                f"with, or '{fix}'."
            )
            _model_errors[name] = reason
            print(f"[startup] WARNING: {reason}")
        else:
            note = f"fitted with sklearn {trained_with}, " if trained_with else ""
            print(
                f"[startup] model '{name}' OK ({note}running sklearn "
                f"{sklearn.__version__})"
            )


# ---------------------------------------------------------------------------
# Pydantic schemas
# ---------------------------------------------------------------------------
class PredictRequest(BaseModel):
    model: Literal["logistic_regression", "random_forest"]
    size_score: float
    concentration_flag: int
    top_sector_weight: float
    sector_risk_score: float
    bank_risk_factor: float
    loan_to_asset_ratio: float
    deposit_to_asset_ratio: float
    car_buffer: float
    liquidity_buffer: float
    baseline_roa_pct: float
    severity_score: int
    shock_severity_score: float


class PredictResponse(BaseModel):
    predicted_condition: str
    predicted_condition_code: int
    prob_healthy: float
    prob_stressed: float
    prob_critical: float
    model_used: str


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    if req.model in _model_errors:
        raise HTTPException(503, _model_errors[req.model])
    if req.model not in _models:
        raise HTTPException(404, f"Model '{req.model}' not loaded")

    model = _models[req.model]

    # Feature vector (must match training order exactly)
    features = [
        req.size_score,
        req.concentration_flag,
        req.top_sector_weight,
        req.sector_risk_score,
        req.bank_risk_factor,
        req.loan_to_asset_ratio,
        req.deposit_to_asset_ratio,
        req.car_buffer,
        req.liquidity_buffer,
        req.baseline_roa_pct,
        req.severity_score,
        req.shock_severity_score,
        # Computed interaction features
        req.concentration_flag * req.severity_score,
        req.bank_risk_factor * req.severity_score,
    ]
    X = np.array([features])

    pred = model.predict(X)[0]
    proba = model.predict_proba(X)[0]

    # Map probabilities to named fields
    prob_critical = float(proba[CLASS_INDEX["Critical"]])
    prob_healthy = float(proba[CLASS_INDEX["Healthy"]])
    prob_stressed = float(proba[CLASS_INDEX["Stressed"]])

    return PredictResponse(
        predicted_condition=str(pred),
        predicted_condition_code=CLASS_INDEX.get(str(pred), -1),
        prob_healthy=prob_healthy,
        prob_stressed=prob_stressed,
        prob_critical=prob_critical,
        model_used=req.model,
    )


# ---------------------------------------------------------------------------
# Recommendation / Explanation endpoint (LLM-powered)
# ---------------------------------------------------------------------------
class RecommendRequest(BaseModel):
    model: Literal["logistic_regression", "random_forest"]
    predicted_condition: str
    prob_healthy: float
    prob_stressed: float
    prob_critical: float
    size_score: float
    concentration_flag: int
    top_sector_weight: float
    sector_risk_score: float
    bank_risk_factor: float
    loan_to_asset_ratio: float
    deposit_to_asset_ratio: float
    car_buffer: float
    liquidity_buffer: float
    baseline_roa_pct: float
    severity_score: int
    shock_severity_score: float


class RecommendResponse(BaseModel):
    explanation: str
    key_drivers: list[str]
    next_steps: list[str]


_FEATURE_DESCRIPTIONS = {
    "size_score": "Bank size score (0=small, 1=large)",
    "concentration_flag": "Whether the bank has concentrated lending (0=No, 1=Yes)",
    "top_sector_weight": "Weight of the top lending sector in the bank's portfolio (0-1)",
    "sector_risk_score": "Risk score of the top sector (higher = riskier sector)",
    "bank_risk_factor": "Bank-specific risk factor (higher = more inherent risk)",
    "loan_to_asset_ratio": "Loans as a fraction of total assets (higher = more lending exposure)",
    "deposit_to_asset_ratio": "Deposits as a fraction of total assets (higher = more stable funding)",
    "car_buffer": "Capital Adequacy Ratio buffer above regulatory minimum (percentage points)",
    "liquidity_buffer": "Liquidity buffer as percentage of total assets",
    "baseline_roa_pct": "Baseline Return on Assets percentage (profitability measure)",
    "severity_score": "Macro shock severity level (1=Mild, 2=Moderate, 3=Severe)",
    "shock_severity_score": "Continuous shock severity score (normalized 0-1)",
}

_SYSTEM_PROMPT = """You are an expert banking risk analyst specializing in stress testing for Pakistani banks. You analyze stress-test prediction results and provide clear, actionable explanations and recommendations.

You will be given:
- The predicted bank health condition (Healthy / Stressed / Critical)
- Class probabilities from the ML model
- All input feature values used for the prediction

Feature descriptions:
- size_score: Bank size score (0=small, 1=large)
- concentration_flag: Whether the bank has concentrated lending (0=No, 1=Yes)
- top_sector_weight: Weight of the top lending sector (0-1)
- sector_risk_score: Risk score of the top sector (higher = riskier)
- bank_risk_factor: Bank-specific risk factor (higher = more risk)
- loan_to_asset_ratio: Loans as fraction of total assets
- deposit_to_asset_ratio: Deposits as fraction of total assets (higher = more stable funding)
- car_buffer: Capital Adequacy Ratio buffer above regulatory minimum (percentage points)
- liquidity_buffer: Liquidity buffer as % of assets
- baseline_roa_pct: Baseline Return on Assets % (profitability)
- severity_score: Macro shock severity (1=Mild, 2=Moderate, 3=Severe)
- shock_severity_score: Continuous shock severity (0-1)

RULES:
- Only use the exact values provided above. Do not calculate, estimate, or infer any numbers not explicitly given.
- If the input looks like placeholder/test data (e.g. all values are 0, or predicted_condition is not one of Healthy/Stressed/Critical), respond with a JSON object where "explanation" states the input appears invalid or incomplete, and "key_drivers"/"next_steps" are empty arrays.
- If the top two class probabilities are within 10 percentage points of each other, explicitly note in "explanation" that the prediction is borderline/uncertain.
- When citing a feature value in key_drivers, format it clearly with its unit (e.g. "car_buffer: 1.2 percentage points — below the typical 2.5pp safety margin").

IMPORTANT: Respond with ONLY a valid JSON object. Do not wrap it in markdown, code fences, or add any text before or after it. Use exactly this format:
{
  "explanation": "2-3 sentences explaining why this bank received this prediction. Reference specific feature values that drove the result. Be precise about which values are concerning vs healthy.",
  "key_drivers": ["3-5 specific features that most influenced this prediction, each with the actual value and whether it helped or hurt the bank's position"],
  "next_steps": ["3-5 concrete, actionable recommendations. If Critical: focus on immediate capital/liquidity actions. If Stressed: focus on preventive measures. If Healthy: focus on maintaining buffers and monitoring."]
}"""

@app.post("/recommend", response_model=RecommendResponse)
async def recommend(req: RecommendRequest):
    api_key = os.getenv("LLM_API_KEY", "")
    base_url = os.getenv("LLM_BASE_URL", "")
    model_name = os.getenv("LLM_MODEL", "qwen-plus")

    if not api_key or not base_url:
        raise HTTPException(
            500,
            "LLM not configured. Set LLM_API_KEY and LLM_BASE_URL in backend/.env",
        )

    from openai import AsyncOpenAI

    client = AsyncOpenAI(api_key=api_key, base_url=base_url)

    user_content = (
        f"Prediction Result:\n"
        f"- Predicted Condition: {req.predicted_condition}\n"
        f"- P(Healthy): {req.prob_healthy:.1%}\n"
        f"- P(Stressed): {req.prob_stressed:.1%}\n"
        f"- P(Critical): {req.prob_critical:.1%}\n"
        f"- Model Used: {req.model}\n\n"
        f"Input Features:\n"
        f"- size_score: {req.size_score}\n"
        f"- concentration_flag: {req.concentration_flag}\n"
        f"- top_sector_weight: {req.top_sector_weight}\n"
        f"- sector_risk_score: {req.sector_risk_score}\n"
        f"- bank_risk_factor: {req.bank_risk_factor}\n"
        f"- loan_to_asset_ratio: {req.loan_to_asset_ratio}\n"
        f"- deposit_to_asset_ratio: {req.deposit_to_asset_ratio}\n"
        f"- car_buffer: {req.car_buffer}\n"
        f"- liquidity_buffer: {req.liquidity_buffer}\n"
        f"- baseline_roa_pct: {req.baseline_roa_pct}\n"
        f"- severity_score: {req.severity_score}\n"
        f"- shock_severity_score: {req.shock_severity_score}\n"
    )

    try:
        response = await client.chat.completions.create(
            model=model_name,
            messages=[
                {"role": "system", "content": _SYSTEM_PROMPT},
                {"role": "user", "content": user_content},
            ],
            temperature=0.7,
            max_tokens=1024,
        )
        raw = response.choices[0].message.content.strip()

        # Strip markdown code fences if the model wraps in ```json ... ```
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[-1].rsplit("```", 1)[0].strip()

        parsed = json.loads(raw)
        return RecommendResponse(
            explanation=parsed.get("explanation", ""),
            key_drivers=parsed.get("key_drivers", []),
            next_steps=parsed.get("next_steps", []),
        )
    except json.JSONDecodeError as exc:
        # If the LLM returns non-JSON, wrap the raw text as the explanation
        return RecommendResponse(
            explanation=raw if "raw" in dir() else "Could not parse LLM response.",
            key_drivers=[],
            next_steps=[],
        )
    except Exception as exc:
        raise HTTPException(502, f"LLM API error: {exc}")


# ---------------------------------------------------------------------------
# Metrics endpoint
# ---------------------------------------------------------------------------
@app.get("/metrics/{model_name}")
def get_metrics(model_name: str):
    pred_csv = OUTPUT_DIR / f"{model_name}_predictions.csv"
    if not pred_csv.exists():
        raise HTTPException(404, f"Predictions file not found for {model_name}")

    df = pd.read_csv(pred_csv)

    from sklearn.metrics import classification_report

    y_true = df["actual_condition"]
    y_pred = df["predicted_condition"]
    report = classification_report(y_true, y_pred, output_dict=True, zero_division=0)

    accuracy = report.pop("accuracy", 0.0)
    macro_avg = report.pop("macro avg", {})
    weighted_avg = report.pop("weighted avg", {})

    # Normalize keys: sklearn uses 'f1-score', frontend expects 'f1_score'
    def normalize(d):
        return {k.replace("-", "_"): v for k, v in d.items()}

    return {
        "model_name": model_name,
        "accuracy": float(accuracy),
        "macro_avg": normalize(macro_avg),
        "weighted_avg": normalize(weighted_avg),
        "per_class": {cls: normalize(vals) for cls, vals in report.items()},
    }


# ---------------------------------------------------------------------------
# Banks endpoint
# ---------------------------------------------------------------------------
@app.get("/banks")
def get_banks():
    # Read from the first predictions CSV (any model will do)
    for name in ["logistic_regression", "random_forest", "xgboost"]:
        pred_csv = OUTPUT_DIR / f"{name}_predictions.csv"
        if pred_csv.exists():
            df = pd.read_csv(pred_csv)
            break
    else:
        return []

    grouped = df.groupby("bank_id")["predicted_condition"].value_counts(normalize=True).unstack(fill_value=0)

    result = []
    for bank_id in sorted(df["bank_id"].unique()):
        row = grouped.loc[bank_id] if bank_id in grouped.index else pd.Series()
        total = int(df[df["bank_id"] == bank_id].shape[0])
        result.append(
            {
                "bank_id": bank_id,
                "total_simulations": total,
                "healthy_pct": float(row.get("Healthy", 0)) * 100,
                "stressed_pct": float(row.get("Stressed", 0)) * 100,
                "critical_pct": float(row.get("Critical", 0)) * 100,
            }
        )
    return result


@app.get("/banks/{bank_id}")
def get_bank_detail(bank_id: str):
    from urllib.parse import unquote

    bank_id = unquote(bank_id)

    # Try to get profile
    profile_path = PROJECT_ROOT / "processed" / "bank_profiles_clean.csv"
    profile = {}
    if profile_path.exists():
        profiles = pd.read_csv(profile_path)
        match = profiles[profiles["bank_id"] == bank_id]
        if not match.empty:
            profile = match.iloc[0].to_dict()

    # Get simulations from predictions
    simulations = []
    for name in ["logistic_regression"]:
        pred_csv = OUTPUT_DIR / f"{name}_predictions.csv"
        if pred_csv.exists():
            df = pd.read_csv(pred_csv)
            bank_df = df[df["bank_id"] == bank_id]
            simulations = bank_df.to_dict(orient="records")
            break

    return {"bank_id": bank_id, "profile": profile, "simulations": simulations}


# ---------------------------------------------------------------------------
# Scenarios endpoint
# ---------------------------------------------------------------------------
@app.get("/scenarios")
def get_scenarios():
    for name in ["logistic_regression", "random_forest", "xgboost"]:
        pred_csv = OUTPUT_DIR / f"{name}_predictions.csv"
        if pred_csv.exists():
            df = pd.read_csv(pred_csv)
            break
    else:
        return []

    result = []
    for sid, group in df.groupby("scenario_id"):
        counts = group["predicted_condition"].value_counts(normalize=True)
        dominant = counts.idxmax()
        result.append(
            {
                "scenario_id": str(sid),
                "num_banks": len(group),
                "dominant_condition": dominant,
                "healthy_pct": float(counts.get("Healthy", 0)) * 100,
                "stressed_pct": float(counts.get("Stressed", 0)) * 100,
                "critical_pct": float(counts.get("Critical", 0)) * 100,
            }
        )
    result.sort(key=lambda x: x["scenario_id"])
    return result


# ---------------------------------------------------------------------------
# Static file serving for reports and evaluation images
# ---------------------------------------------------------------------------
@app.get("/reports/{filename}")
def get_report(filename: str):
    for d in [OUTPUT_DIR, REPORTS_DIR]:
        path = d / filename
        if path.exists():
            return FileResponse(path)
    raise HTTPException(404, f"Report '{filename}' not found")


# Serve evaluation images from dashboard/public/evaluation
EVAL_DIR = PROJECT_ROOT / "dashboard" / "public" / "evaluation"
if EVAL_DIR.exists():
    app.mount("/evaluation", StaticFiles(directory=str(EVAL_DIR)), name="evaluation")
