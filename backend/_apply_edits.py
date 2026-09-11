"""One-shot patcher for backend/main.py (file-save tools are blocked in this session)."""

PATH = r"c:\Users\User\Downloads\bank-stress-testing-simulator\backend\main.py"

OLD1 = '''# Class label order from trained models: ['Critical', 'Healthy', 'Stressed']
CLASS_ORDER = ["Critical", "Healthy", "Stressed"]
CLASS_INDEX = {c: i for i, c in enumerate(CLASS_ORDER)}'''

NEW1 = '''# Class label order from trained models: ['Critical', 'Healthy', 'Stressed']
CLASS_ORDER = ["Critical", "Healthy", "Stressed"]
CLASS_INDEX = {c: i for i, c in enumerate(CLASS_ORDER)}

# 12 raw features + 2 server-side interaction terms (see /predict)
N_FEATURES = 14'''

OLD2 = '''_models: dict = {}


@app.on_event("startup")
def load_models():
    lr_path = MODELS_DIR / "linear_regression_model.pkl"
    rf_path = MODELS_DIR / "random_forest_model.pkl"
    if lr_path.exists():
        _models["logistic_regression"] = joblib.load(lr_path)
    if rf_path.exists():
        _models["random_forest"] = joblib.load(rf_path)'''

NEW2 = '''_models: dict = {}
_model_errors: dict = {}  # model name -> reason it cannot serve predictions


@app.on_event("startup")
def load_models():
    lr_path = MODELS_DIR / "linear_regression_model.pkl"
    rf_path = MODELS_DIR / "random_forest_model.pkl"
    if lr_path.exists():
        _models["logistic_regression"] = joblib.load(lr_path)
    if rf_path.exists():
        _models["random_forest"] = joblib.load(rf_path)

    # Smoke-test each model: scikit-learn pickles only work under the version
    # they were trained with, so surface that problem at startup instead of
    # crashing with a confusing 500 on the first /predict request.
    import warnings

    import sklearn

    for name, model in _models.items():
        trained_with = getattr(model, "_sklearn_version", "unknown")
        try:
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                probe = np.zeros((1, N_FEATURES))
                model.predict(probe)
                model.predict_proba(probe)
        except Exception as exc:
            fix = (
                f"pip install scikit-learn=={trained_with}"
                if trained_with != "unknown"
                else "re-fit the models under the installed scikit-learn version"
            )
            reason = (
                f"Model '{name}' was trained with scikit-learn {trained_with} "
                f"but this server runs scikit-learn {sklearn.__version__}; "
                f"scikit-learn pickles are not compatible across versions "
                f"(error: {exc!r}). Fix: run the backend with the interpreter "
                f"the models were trained with, or '{fix}'."
            )
            _model_errors[name] = reason
            print(f"[startup] WARNING: {reason}")
        else:
            print(
                f"[startup] model '{name}' OK (trained with sklearn "
                f"{trained_with}, running sklearn {sklearn.__version__})"
            )'''

OLD3 = '''@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    if req.model not in _models:
        raise HTTPException(404, f"Model '{req.model}' not loaded")'''

NEW3 = '''@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    if req.model in _model_errors:
        raise HTTPException(503, _model_errors[req.model])
    if req.model not in _models:
        raise HTTPException(404, f"Model '{req.model}' not loaded")'''

with open(PATH, "r", encoding="utf-8", newline="") as f:
    src = f.read()

crlf = "\r\n" in src


def normalize(s: str) -> str:
    s = s.replace("\r\n", "\n")
    return s.replace("\n", "\r\n") if crlf else s


for i, (old, new) in enumerate([(OLD1, NEW1), (OLD2, NEW2), (OLD3, NEW3)], 1):
    old, new = normalize(old), normalize(new)
    count = src.count(old)
    if count != 1:
        raise SystemExit(f"ABORT: anchor {i} matched {count} times")
    src = src.replace(old, new)

with open(PATH, "w", encoding="utf-8", newline="") as f:
    f.write(src)

print(f"main.py patched: 3 edits applied ({'CRLF' if crlf else 'LF'} endings)")
