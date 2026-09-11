"""Patch 2 for backend/main.py: capture training sklearn version during load."""

PATH = r"c:\Users\User\Downloads\bank-stress-testing-simulator\backend\main.py"

OLD = '''_models: dict = {}
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

NEW = '''_models: dict = {}
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
            )'''

with open(PATH, "r", encoding="utf-8", newline="") as f:
    src = f.read()

crlf = "\r\n" in src


def normalize(s: str) -> str:
    s = s.replace("\r\n", "\n")
    return s.replace("\n", "\r\n") if crlf else s


old, new = normalize(OLD), normalize(NEW)
count = src.count(old)
if count != 1:
    raise SystemExit(f"ABORT: anchor matched {count} times")

src = src.replace(old, new)

with open(PATH, "w", encoding="utf-8", newline="") as f:
    f.write(src)

print(f"main.py patch 2 applied ({'CRLF' if crlf else 'LF'})")
