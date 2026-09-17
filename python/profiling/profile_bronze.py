import pandas as pd  # pyright: ignore[reportMissingModuleSource]
from sqlalchemy import create_engine  # pyright: ignore[reportMissingImports]

# --------------------------------------------------
# PostgreSQL connection
# --------------------------------------------------

from urllib.parse import quote_plus

DB_USER = "postgres"
DB_PASSWORD = "Back@1304"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "DA-1"

encoded_password = quote_plus(DB_PASSWORD)

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{encoded_password}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# --------------------------------------------------
# Bronze tables
# --------------------------------------------------

tables = [
    "iot_manufacturing",
    "manufacturing",
    "erp_inventory",
    "erp_purchase_orders",
    "sales_pipeline"
]

# --------------------------------------------------
# Profiling function
# --------------------------------------------------

def profile_table(table_name):

    query = f"""
        SELECT *
        FROM bronze.{table_name}
    """

    df = pd.read_sql(query, engine)

    print("\n" + "=" * 70)
    print(f"TABLE: bronze.{table_name}")
    print("=" * 70)

    # Shape
    print("\nRows:", df.shape[0])
    print("Columns:", df.shape[1])

    # Column names
    print("\nColumns:")
    print(df.columns.tolist())

    # Data types
    print("\nData Types:")
    print(df.dtypes)

    # Missing values
    print("\nMissing Values:")
    print(df.isnull().sum())

    # Duplicate rows
    print("\nDuplicate Rows:")
    print(df.duplicated().sum())

    # Unique values
    print("\nUnique Values:")
    print(df.nunique())

    # Numerical statistics
    print("\nNumerical Statistics:")
    print(df.describe(include="all").transpose())


# --------------------------------------------------
# Run profiling
# --------------------------------------------------

for table in tables:
    profile_table(table)

print("\nProfiling completed successfully.")