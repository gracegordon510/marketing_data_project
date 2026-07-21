from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]

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
    return {
        "customers": extract_customers(),
        "products": extract_products(),
        "campaigns": extract_campaigns(),
        "events": extract_events(),
        "transactions": extract_transactions(),
    }


print(RAW_DATA_DIR)
print(RAW_DATA_DIR.exists())

if __name__ == "__main__":
    tables = extract_all()

    for table_name, dataframe in tables.items():
        print(table_name, dataframe.shape)
