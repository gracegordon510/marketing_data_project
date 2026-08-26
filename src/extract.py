"""Extract csv files."""

from src.config import PROJECT_ROOT
import pandas as pd
import logging

logger = logging.getLogger("marketing_etl")

RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"


def extract_customers() -> pd.DataFrame:
    return pd.read_csv(RAW_DATA_DIR / "customers.csv")


def extract_products() -> pd.DataFrame:
    return pd.read_csv(RAW_DATA_DIR / "products.csv")


def extract_campaigns() -> pd.DataFrame:
    return pd.read_csv(RAW_DATA_DIR / "campaigns.csv")


def extract_events() -> pd.DataFrame:
    return pd.read_csv(RAW_DATA_DIR / "events.csv")


def extract_transactions() -> pd.DataFrame:
    return pd.read_csv(RAW_DATA_DIR / "transactions.csv")


def extract_all() -> dict[str, pd.DataFrame]:
    tables = {
        "customers": extract_customers(),
        "products": extract_products(),
        "campaigns": extract_campaigns(),
        "events": extract_events(),
        "transactions": extract_transactions(),
    }

    for table_name, df in tables.items():
        logger.info(
            "Extracted %s: %s rows, %s columns.",
            table_name,
            f"{len(df):,}",
            len(df.columns),
        )

    return tables
