---
title: Data Science / ML / Notebook Instruction
type: instruction
description: "Conventions for data science, ML, and notebook-driven projects using Jupyter, pandas, scikit-learn, DuckDB, and the medallion lakehouse architecture."
applyTo:
  - data-science
  - ml
  - notebook
  - jupyter
  - duckdb
  - pandas
  - scikit-learn
---

# Data Science / ML / Notebook Instruction

This instruction file defines conventions for data science, ML, and notebook-driven projects. Follow these patterns to ensure reproducibility, maintainability, and collaboration across teams.

## Project Structure

Organize data science projects with clear separation of concerns.

```
project/
├── data/
│   ├── raw/                 # Unmodified source data
│   ├── bronze/              # Raw ingested data (medallion)
│   ├── silver/              # Cleaned, deduplicated data
│   └── gold/                # Aggregated, business-ready data
├── notebooks/
│   ├── 01_exploratory_analysis.ipynb
│   ├── 02_data_preparation.ipynb
│   └── 03_model_training.ipynb
├── src/
│   ├── __init__.py
│   ├── data.py              # Data loading, transformation
│   ├── features.py          # Feature engineering
│   └── models.py            # Model training, evaluation
├── tests/
│   ├── test_data.py
│   └── test_features.py
├── results/
│   ├── models/              # Trained model artifacts
│   ├── figures/             # Generated plots
│   └── metrics.json         # Model performance metrics
├── requirements.txt         # Python dependencies (pinned)
├── environment.yml          # Conda environment (optional)
├── pyproject.toml          # Project metadata
└── README.md               # Project overview
```

## Notebook Idempotency

Notebooks must execute top-to-bottom without errors, enabling reproducibility and CI/CD integration.

- **No hidden state:** Avoid relying on cells run out-of-order.
- **Restart kernel before commit:** Use Kernel → Restart & Run All to verify end-to-end execution.
- **Initialize variables at the top:** Set random seeds, file paths, and configuration in the first cell.
- **One logical flow:** Structure notebooks as sequential stages (Load → Clean → Explore → Engineer → Train → Evaluate).

**First cell template:**

```python
# Configuration
import numpy as np
import pandas as pd
from pathlib import Path

# Set random seed for reproducibility
np.random.seed(42)

# Define paths
DATA_DIR = Path.cwd() / "data"
RAW_DATA = DATA_DIR / "raw" / "dataset.csv"
PROCESSED_DATA = DATA_DIR / "silver" / "processed.parquet"
```

## Cell Output Hygiene

Committing cell outputs bloats repositories and clutters version control diffs.

- **Clear outputs before committing:** Use Kernel → Restart & Clear Output in Jupyter.
- **Alternative for automation:** Use `nbstripout` to automatically strip outputs pre-commit.
- **Large visualizations:** Save plots to disk instead of embedding in notebook cells.
- **Data inspection:** Use `.head()`, `.info()`, `.describe()` (which are fine to keep) rather than printing entire datasets.

**Install nbstripout:**

```bash
pip install nbstripout
nbstripout --install  # Installs git hook
```

## Reproducibility

Reproducible workflows enable others to verify results and build on your work.

- **Pin all dependencies** in `requirements.txt` or `environment.yml` with exact versions.
- **Document data sources:** Include URLs, download dates, and checksums for raw data.
- **Fix random seeds** at project initialization (`np.random.seed()`, `torch.manual_seed()`).
- **Record environment metadata:** Python version, library versions, hardware (GPU model, CPU count).
- **Version control scripts, not outputs:** Commit `.py` files and notebooks, not model files or large CSVs.

**Environment documentation:**

```markdown
## Environment

- Python 3.11.5
- PyTorch 2.0.1 (CUDA 12.1)
- scikit-learn 1.3.2
- pandas 2.1.1

Run: `pip install -r requirements.txt` to reproduce.
```

## Train/Test Split

Proper data splitting prevents data leakage and enables honest model evaluation.

- **Use a fixed random seed** for reproducible splits.
- **Stratified splits for classification:** Use `train_test_split(..., stratify=y)` to maintain class distribution.
- **Time-series splits:** Use `TimeSeriesSplit()` or walk-forward validation for temporal data; never shuffle.
- **Cross-validation:** Use `cross_val_score()` or `KFold` for robust evaluation.
- **No leakage:** Fit scalers/encoders on training data only, then apply to test data.

**Example:**

```python
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.preprocessing import StandardScaler

# Stratified split for classification
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

# Fit scaler on training data only
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)  # Apply, don't refit
```

## Feature Engineering

Modularize feature engineering into reusable functions for clarity and testing.

- **Keep features interpretable:** Avoid blackbox transformations; document what each feature represents.
- **One transformation per function:** Separate scaling, encoding, and domain logic.
- **Use pipelines:** `sklearn.pipeline.Pipeline` chains transformations for reproducibility.
- **Document feature selection:** Record which features were selected and why (correlation, domain knowledge, feature importance).

**Example:**

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.compose import ColumnTransformer

# Define transformers
numeric_transformer = Pipeline([
    ("scaler", StandardScaler())
])

preprocessor = ColumnTransformer([
    ("num", numeric_transformer, numeric_features)
])

# Full pipeline
full_pipeline = Pipeline([
    ("preprocessor", preprocessor),
    ("model", LogisticRegression())
])

# Fit on training data
full_pipeline.fit(X_train, y_train)

# Evaluate
score = full_pipeline.score(X_test, y_test)
```

## Data Validation

Validate data quality before processing to catch issues early.

- **Schema validation:** Use `pandera` to enforce column names, types, and value ranges.
- **Null/missing checks:** Log and handle missing values consistently.
- **Range checks:** Verify numeric values are within expected bounds.
- **Deduplication:** Detect and handle duplicate rows.

**Example with pandera:**

```python
import pandera as pa

schema = pa.DataFrameSchema({
    "user_id": pa.Column(pa.Int64, checks=pa.Check.greater_than(0)),
    "age": pa.Column(pa.Int32, checks=[
        pa.Check.greater_than_or_equal_to(0),
        pa.Check.less_than_or_equal_to(150)
    ]),
    "email": pa.Column(pa.String, nullable=False)
})

# Validate
validated_df = schema.validate(df)
```

## Medallion Architecture (Lakehouse Pattern)

Organize data pipelines with bronze/silver/gold layers for clarity and quality control.

- **Bronze layer:** Raw, unmodified ingested data. Minimal transformations (e.g., compression, partitioning).
- **Silver layer:** Cleaned, deduplicated, validated data. Schema enforced, PII removed.
- **Gold layer:** Aggregated, business-ready data. Joined, denormalized for analytics/BI.

**Each layer documents:**
- Data quality checks applied.
- Transformations performed.
- Update frequency (daily, weekly, etc.).
- Owner and SLA.

**Example directory structure:**

```
data/
├── bronze/
│   ├── raw_events_2024_01_01.parquet
│   ├── raw_users_2024_01_01.parquet
├── silver/
│   ├── events_cleaned.parquet
│   ├── users_deduplicated.parquet
├── gold/
│   ├── daily_user_engagement.parquet
│   ├── user_cohorts.parquet
```

## Model Training & Evaluation

Track experiments and document model performance to enable comparison and improvement.

- **Log metrics:** Use `pandas` DataFrames or MLflow to log hyperparameters, train/test accuracy, AUC, etc.
- **Save best model:** Pickle, joblib, or ONNX to `results/models/`.
- **Document baseline:** Record baseline (e.g., random guess, previous model) for context.
- **Confusion matrix & ROC:** For classification, always plot confusion matrix and ROC curve.

**Example:**

```python
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
import json

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train_scaled, y_train)

# Evaluate
y_pred = model.predict(X_test_scaled)
metrics = {
    "accuracy": model.score(X_test_scaled, y_test),
    "auc": roc_auc_score(y_test, model.predict_proba(X_test_scaled)[:, 1]),
    "classification_report": classification_report(y_test, y_pred, output_dict=True)
}

# Save metrics
with open("results/metrics.json", "w") as f:
    json.dump(metrics, f, indent=2)

# Save model
import joblib
joblib.dump(model, "results/models/random_forest_v1.pkl")
```

## Testing Notebooks and Data Pipelines

Unit test critical logic; integration test end-to-end pipelines.

- **Unit tests:** Test data loading, feature engineering, and model logic in `src/` modules via `pytest`.
- **Integration tests:** Use `nbval` or `papermill` to execute notebooks and verify outputs.
- **Data tests:** Validate output datasets against schemas using `pandera`.

**Install nbval and run:**

```bash
pip install nbval
pytest --nbval notebooks/
```

**Example with papermill (parameterized notebooks):**

```python
import papermill as pm

pm.execute_notebook(
    "notebooks/02_data_preparation.ipynb",
    "outputs/02_data_preparation.ipynb",
    parameters={"input_file": "data/raw/test.csv"}
)
```

## Platform Guidance

### Microsoft Fabric Spark

When using Fabric Spark for large-scale data pipelines:

- **Data access:** Use `pandas` with Fabric shortcuts (`spark.read.csv()` → `to_pandas()`).
- **Partitioning:** Partition large tables by date or category for performance.
- **Serialization:** Use Parquet (not CSV) for efficient Spark table I/O.
- **PySpark vs. pandas:** Use PySpark for 10GB+; pandas for <1GB per partition.
- **Workspace organization:** Keep notebooks, lakehouse tables, and models organized by domain (e.g., `Finance_Models`, `Marketing_Data`).

### Jupyter Best Practices

- **Notebook naming:** Use numeric prefixes (`01_`, `02_`) to indicate execution order.
- **Cell length:** Keep cells <50 lines for readability; split complex logic into functions in `src/`.
- **Markdown documentation:** Use markdown cells to document each section's purpose and assumptions.
- **Kernel restart:** Use Kernel → Restart & Run All before committing to ensure reproducibility.

### DuckDB for Analytics and ETL

DuckDB is an in-process SQL database ideal for analytical workloads and data pipelines, especially within notebooks and Python applications.

- **Install:** `pip install duckdb`
- **Use cases:** SQL queries on pandas DataFrames, Parquet files, or CSV without data movement; fast aggregations; analytics within notebooks
- **Performance:** Vectorized execution; 10-100x faster than pandas for large datasets
- **Integration:** Works seamlessly with pandas, Parquet, Polars, and Apache Arrow

**Basic usage in notebooks:**

```python
import duckdb
import pandas as pd

# Query pandas DataFrame directly
df = pd.read_csv("data.csv")
result = duckdb.sql("SELECT * FROM df WHERE value > 100").pl()

# Or query Parquet files
result = duckdb.sql("SELECT COUNT(*) FROM read_parquet('data/silver/*.parquet')").df()

# Export to pandas
output_df = result.df()
```

**Medallion architecture with DuckDB:**

```python
import duckdb

# Bronze → Silver transformation
duckdb.sql("""
    CREATE TABLE silver.users AS
    SELECT
        user_id,
        CAST(created_at AS DATE) as created_date,
        email
    FROM read_parquet('data/bronze/users_raw_*.parquet')
    WHERE email IS NOT NULL
""")

# Silver → Gold aggregation
duckdb.sql("""
    CREATE TABLE gold.daily_users AS
    SELECT
        created_date,
        COUNT(DISTINCT user_id) as daily_signups
    FROM silver.users
    GROUP BY created_date
""")

# Export result
result = duckdb.sql("SELECT * FROM gold.daily_users").df()
result.to_parquet("data/gold/daily_users.parquet")
```

**Performance tips:**

- Use `read_parquet()` instead of reading to pandas for large files
- Use `SELECT ... LIMIT` to preview data quickly
- Use window functions (`ROW_NUMBER()`, `LAG()`) for advanced analytics
- Push aggregations to SQL; only bring small results to pandas
- Use connection pooling for multi-notebook workflows

**Integrating with Microsoft Fabric:**

- Load Fabric lakehouse tables via Spark integration
- Query Bronze/Silver/Gold layers without intermediate pandas copies
- Use DuckDB for local development, Spark for production scale-out

## See Also

- `python.instructions.md` — General Python coding standards (type hints, linting, packaging).
- `docs/NOTEBOOK_CONVENTIONS.md` — Extended notebook style guide (cell organization, naming).
- `testing.instructions.md` — General testing patterns and CI/CD integration.
