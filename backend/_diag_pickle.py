"""Diagnostic: check pickle/sklearn compatibility for the stress-test models."""
import sys
import joblib
import sklearn

print(f"interpreter : {sys.executable}")
print(f"sklearn     : {sklearn.__version__}")

MODELS = [
    r"c:\Users\User\Downloads\bank-stress-testing-simulator\models\linear_regression_model.pkl",
    r"c:\Users\User\Downloads\bank-stress-testing-simulator\models\random_forest_model.pkl",
]

# 12 raw features + 2 interaction terms, order must match training
X = [[3.0, 1, 0.28, 2.1, 0.55, 0.62, 0.75, 0.04, 0.15, 1.2, 3, 7.5, 1 * 3, 0.55 * 3]]

for path in MODELS:
    m = joblib.load(path)
    imputer = None
    if hasattr(m, "named_steps"):
        print(f"\n{path.split(chr(92))[-1]} -> pipeline steps: {list(m.named_steps)}")
        for step in m.named_steps.values():
            if step.__class__.__name__ == "SimpleImputer":
                imputer = step
    if imputer is not None:
        has = hasattr(imputer, "_fill_dtype")
        print(f"  imputer strategy={imputer.strategy!r}, has _fill_dtype: {has}")
        if has:
            print(f"  _fill_dtype = {imputer._fill_dtype}")
    try:
        pred = m.predict(X)[0]
        proba = m.predict_proba(X)[0]
        print(f"  predict OK -> {pred}, proba={proba.round(3).tolist()}")
    except Exception as e:
        print(f"  predict FAILED -> {type(e).__name__}: {e}")
