---
description: "Comprehensive test suite for data workloads: medallion patterns, data quality validation, and convention-driven testing for bronze/silver/gold layers."
applyTo: "**/*.{py,sql,yml}"
---

# Data Workload Testing Convention

## Overview

Data workload tests validate the correctness, completeness, and quality of data transformations across medallion architecture layers. This guide establishes conventions for test organization, naming, validation patterns, and assertion frameworks.

## Test Categories

### 1. Data Integrity Tests

Validate that data transformations preserve correctness.

#### Schema Validation

```python
# tests/data/test_silver_orders.py
import pytest
from pydantic import BaseModel, Field, validator
from typing import List

class OrderSchema(BaseModel):
    order_id: str
    customer_id: str
    order_amount: float = Field(..., gt=0)
    order_date: str
    
    @validator('order_date')
    def validate_date_format(cls, v):
        # ISO 8601 format
        assert len(v) == 10 and v[4] == '-' and v[7] == '-'
        return v

def test_silver_orders_schema(spark_session):
    """Validate that silver.orders matches expected schema."""
    df = spark_session.table("silver.orders")
    
    for record in df.toJSON().collect():
        OrderSchema(**json.loads(record))
```

#### Referential Integrity

```sql
-- tests/data/silver_referential_integrity.sql
-- Validate that all foreign keys exist in parent tables

SELECT COUNT(*) as orphaned_records
FROM silver.order_items oi
LEFT JOIN silver.orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
HAVING COUNT(*) > 0;

-- Expected: 0 orphaned records
```

#### Data Type Consistency

```python
def test_data_types_silver_users(spark_session):
    """Ensure data types match schema definition."""
    df = spark_session.table("silver.users")
    
    expected_types = {
        'user_id': 'string',
        'email': 'string',
        'signup_date': 'timestamp',
        'lifetime_value': 'decimal(12,2)'
    }
    
    schema_dict = {field.name: field.dataType.typeName() 
                   for field in df.schema.fields}
    
    for col, expected_type in expected_types.items():
        assert schema_dict[col] == expected_type, \
            f"Column {col}: expected {expected_type}, got {schema_dict[col]}"
```

### 2. Data Quality Tests

Validate completeness, accuracy, and conformance.

#### Completeness (NULL rates)

```python
def test_silver_completeness(spark_session):
    """Validate acceptable null rates per column."""
    df = spark_session.table("silver.orders")
    
    null_thresholds = {
        'order_id': 0.0,        # 0% nulls allowed
        'customer_id': 0.0,
        'order_amount': 0.0,
        'shipping_address': 0.05  # 5% nulls allowed
    }
    
    for col, threshold in null_thresholds.items():
        null_rate = df.filter(f.col(col).isNull()).count() / df.count()
        assert null_rate <= threshold, \
            f"Column {col}: null rate {null_rate} exceeds threshold {threshold}"
```

#### Accuracy (Range Validation)

```python
def test_silver_value_ranges(spark_session):
    """Validate that values are within expected ranges."""
    df = spark_session.table("silver.orders")
    
    # Order amounts between $0.01 and $999,999.99
    invalid_amounts = df.filter(
        (f.col('order_amount') < 0.01) | (f.col('order_amount') > 999999.99)
    ).count()
    assert invalid_amounts == 0, f"Found {invalid_amounts} invalid amounts"
    
    # Order dates within last 5 years
    df_with_age = df.withColumn(
        'age_days', 
        f.datediff(f.current_date(), f.col('order_date'))
    )
    future_dates = df_with_age.filter(f.col('age_days') < 0).count()
    assert future_dates == 0, f"Found {future_dates} orders with future dates"
```

#### Uniqueness Constraints

```python
def test_silver_uniqueness(spark_session):
    """Validate that key columns have no unexpected duplicates."""
    df = spark_session.table("silver.products")
    
    # Product IDs should be unique
    duplicate_ids = df.groupBy('product_id').count().filter('count > 1').count()
    assert duplicate_ids == 0, f"Found {duplicate_ids} duplicate product IDs"
```

### 3. Convention Tests

Validate naming conventions, partitioning, and structure.

#### Naming Conventions

```python
import re

def test_column_naming_conventions(spark_session):
    """Enforce snake_case column naming."""
    df = spark_session.table("silver.orders")
    
    snake_case_pattern = re.compile(r'^[a-z][a-z0-9_]*$')
    
    for field in df.schema.fields:
        assert snake_case_pattern.match(field.name), \
            f"Column '{field.name}' violates snake_case convention"
```

#### Partitioning Compliance

```python
def test_partitioning_structure(spark_session, catalog):
    """Validate that tables follow medallion partitioning conventions."""
    # Silver tables: partitioned by year, month, day
    silver_table = spark_session.table("silver.events")
    
    partition_cols = silver_table.partitionColumns
    expected_partitions = ['year', 'month', 'day']
    
    assert partition_cols == expected_partitions, \
        f"Expected {expected_partitions}, got {partition_cols}"
```

#### Metadata Compliance

```python
def test_table_metadata(catalog):
    """Validate that tables have required metadata."""
    for table in catalog.listTables('silver'):
        metadata = table.properties
        
        assert 'owner' in metadata, f"Table {table.name}: missing owner"
        assert 'description' in metadata, f"Table {table.name}: missing description"
        assert 'sla_latency_hours' in metadata, f"Table {table.name}: missing SLA"
```

### 4. Medallion Layer Tests

Layer-specific conventions and validations.

#### Bronze Layer (Raw Data)

```python
def test_bronze_immutability(spark_session):
    """Bronze layer should be append-only (no updates/deletes)."""
    # Check that rows are only added, never modified
    df = spark_session.table("bronze.raw_events")
    
    # Verify timestamps are monotonic
    timestamps = df.select('_loaded_at').rdd.flatMap(lambda x: x).collect()
    assert timestamps == sorted(timestamps), \
        "Bronze table: timestamps not monotonic (data was updated)"
```

```python
def test_bronze_lineage_tracking(spark_session):
    """Bronze layer must track source lineage."""
    df = spark_session.table("bronze.raw_events")
    
    required_lineage_cols = ['_source_system', '_loaded_at', '_file_path']
    
    for col in required_lineage_cols:
        assert col in df.columns, \
            f"Bronze table missing lineage column: {col}"
```

#### Silver Layer (Cleaned Data)

```python
def test_silver_dbt_documentation(catalog):
    """Silver tables should have dbt documentation."""
    silver_tables = catalog.listTables('silver')
    
    for table in silver_tables:
        manifest = read_dbt_manifest('target/manifest.json')
        
        node = manifest['nodes'].get(f'model.analytics.{table.name}')
        assert node is not None, f"Missing dbt documentation for {table.name}"
        assert node.get('description'), f"Missing description for {table.name}"
```

#### Gold Layer (Analytics-Ready)

```python
def test_gold_query_performance(spark_session):
    """Gold layer queries should meet SLA latency targets."""
    import time
    
    query = """
    SELECT 
        date(event_date) as day,
        COUNT(*) as event_count
    FROM gold.daily_events
    WHERE event_date >= DATE_SUB(CURRENT_DATE, 90)
    GROUP BY 1
    """
    
    start = time.time()
    spark_session.sql(query).collect()
    elapsed = time.time() - start
    
    # Gold queries should complete in <5 seconds
    assert elapsed < 5, \
        f"Gold query SLA violated: {elapsed:.2f}s (expected <5s)"
```

### 5. Integration Tests

Cross-layer validation and end-to-end testing.

#### Bronze → Silver Transformation

```python
def test_bronze_to_silver_transformation(spark_session):
    """Validate that all bronze records propagate to silver."""
    bronze_count = spark_session.table("bronze.events").count()
    silver_count = spark_session.table("silver.events").count()
    
    # Allow for deduplication, but not significant loss
    assert silver_count >= bronze_count * 0.95, \
        f"Silver lost >5% of bronze records ({silver_count} vs {bronze_count})"
```

#### Silver → Gold Aggregation

```python
def test_silver_to_gold_aggregation(spark_session):
    """Validate that gold aggregates are correct."""
    # Calculate expected aggregate
    expected = spark_session.sql("""
        SELECT 
            DATE(event_timestamp) as day,
            COUNT(*) as count
        FROM silver.events
        GROUP BY 1
    """)
    
    # Compare with gold
    actual = spark_session.table("gold.daily_event_counts")
    
    diff = expected.except_all(actual)
    assert diff.count() == 0, f"Found {diff.count()} mismatched aggregates"
```

## Test Organization

```
tests/
├── data/
│   ├── bronze/
│   │   └── test_bronze_raw_events.py
│   ├── silver/
│   │   ├── test_silver_events.py
│   │   ├── test_silver_users.py
│   │   └── test_silver_completeness.py
│   ├── gold/
│   │   ├── test_gold_daily_metrics.py
│   │   └── test_gold_query_sla.py
│   ├── integration/
│   │   └── test_end_to_end.py
│   └── conftest.py  # Fixtures
└── sql/
    ├── test_referential_integrity.sql
    └── test_data_quality.sql
```

## Pytest Fixtures

```python
# tests/data/conftest.py
import pytest
from pyspark.sql import SparkSession

@pytest.fixture(scope="session")
def spark_session():
    """Create a Spark session for testing."""
    return SparkSession.builder \
        .appName("data-tests") \
        .config("spark.sql.shuffle.partitions", "1") \
        .getOrCreate()

@pytest.fixture
def sample_bronze_data(spark_session):
    """Load sample bronze data."""
    return spark_session.sql("SELECT * FROM bronze.events LIMIT 1000")
```

## Running Tests

```bash
# All data tests
pytest tests/data/ -v

# Specific test file
pytest tests/data/silver/test_silver_completeness.py -v

# With coverage
pytest tests/data/ --cov=dbt --cov-report=html

# SQL tests
sqlfluff lint dbt/models/silver/ --dialect ansi
dbt test --select tag:critical
```

## CI/CD Integration

```yaml
# .github/workflows/data-quality.yml
name: Data Quality Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run data quality tests
        run: |
          pytest tests/data/ -v --junit-xml=results.xml
      
      - name: dbt test
        run: dbt test --profiles-dir profiles/ --select tag:critical
      
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: results.xml
```

## Key Metrics

| Metric | Target | Tool |
|--------|--------|------|
| Test Coverage | >80% of tables | pytest-cov |
| Data Quality SLA | >99.5% completeness | Great Expectations |
| Query SLA | <5s for gold queries | Spark metrics |
| Freshness SLA | <24h latency | dbt freshness checks |

## References

- [dbt Testing Best Practices](https://docs.getdbt.com/guides/best-practices/testing)
- [Great Expectations Documentation](https://docs.greatexpectations.io/)
- [Medallion Architecture](https://www.databricks.com/en-blog/medallion-architecture-a-proven-approach-to-data-and-ai)
