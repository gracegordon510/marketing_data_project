import pandas as pd


def transform_customers(df: pd.DataFrame) -> pd.DataFrame:

    customers = df.copy()

    customers["customer_id"] = customers["customer_id"].astype("Int64")

    customers["signup_date"] = pd.to_datetime(customers["signup_date"], errors="coerce")

    customers["country"] = customers["country"].str.strip().str.upper()

    customers["gender"] = customers["gender"].str.strip().str.title()

    customers["loyalty_tier"] = customers["loyalty_tier"].str.strip().str.title()

    customers["acquisition_channel"] = (
        customers["acquisition_channel"].str.strip().str.title()
    )

    return customers


def transform_products(df: pd.DataFrame) -> pd.DataFrame:

    products = df.copy()

    products["product_id"] = products["product_id"].astype("Int64")

    products["launch_date"] = pd.to_datetime(products["launch_date"], errors="coerce")

    products["category"] = products["category"].str.strip().str.title()

    products["brand"] = products["brand"].str.strip()

    products["base_price"] = pd.to_numeric(products["base_price"], errors="coerce")

    products["is_premium"] = products["is_premium"].astype("boolean")

    return products


def transform_campaigns(df: pd.DataFrame) -> pd.DataFrame:

    campaigns = df.copy()

    campaigns["campaign_id"] = campaigns["campaign_id"].astype("Int64")

    campaigns["start_date"] = pd.to_datetime(campaigns["start_date"], errors="coerce")

    campaigns["end_date"] = pd.to_datetime(campaigns["end_date"], errors="coerce")

    campaigns["channel"] = campaigns["channel"].str.strip().str.title()

    campaigns["objective"] = campaigns["objective"].str.strip().str.title()

    campaigns["target_segment"] = campaigns["target_segment"].str.strip().str.title()

    campaigns["expected_uplift"] = pd.to_numeric(
        campaigns["expected_uplift"], errors="coerce"
    )

    return campaigns


def transform_events(df: pd.DataFrame) -> pd.DataFrame:

    events = df.copy()

    events["timestamp"] = pd.to_datetime(events["timestamp"], errors="coerce")

    events.rename(columns={"timestamp": "event_timestamp"}, inplace=True)

    events["traffic_source"] = events["traffic_source"].str.strip().str.title()

    events["event_type"] = events["event_type"].str.strip().str.lower()

    events["device_type"] = events["device_type"].str.strip().str.lower()

    events["page_category"] = events["page_category"].str.strip().str.upper()

    events["experiment_group"] = events["experiment_group"].str.strip()

    events["event_id"] = events["event_id"].astype("Int64")
    events["customer_id"] = events["customer_id"].astype("Int64")
    events["product_id"] = events["product_id"].astype("Int64")
    events["campaign_id"] = events["campaign_id"].astype("Int64")

    return events


def transform_transactions(df: pd.DataFrame) -> pd.DataFrame:
    transactions = df.copy()

    transactions["timestamp"] = pd.to_datetime(
        transactions["timestamp"], errors="coerce"
    )

    transactions.rename(
    columns={"timestamp": "transaction_timestamp"},
    inplace=True,
    )

    transactions["quantity"] = pd.to_numeric(
        transactions["quantity"], errors="coerce"
    ).astype("Int64")

    transactions["discount_applied"] = pd.to_numeric(
        transactions["discount_applied"], errors="coerce"
    )

    transactions["gross_revenue"] = pd.to_numeric(
        transactions["gross_revenue"], errors="coerce"
    )

    transactions["refund_flag"] = transactions["refund_flag"].astype("boolean")

    transactions["transaction_id"] = transactions["transaction_id"].astype("Int64")
    transactions["customer_id"] = transactions["customer_id"].astype("Int64")
    transactions["product_id"] = transactions["product_id"].astype("Int64")
    transactions["campaign_id"] = transactions["campaign_id"].astype("Int64")

    unusable_rows = (
        transactions["product_id"].isna() & transactions["gross_revenue"].isna()
    )

    removed_count = unusable_rows.sum()

    transactions = transactions.loc[~unusable_rows].copy()

    print(f"Removed {removed_count:,} unusable transaction rows")

    invalid_rows = transactions[
        transactions["product_id"].isna() & transactions["gross_revenue"].isna()
    ]

    if not invalid_rows.empty:
        raise ValueError(
            "Transactions still contain unusable rows after transformation."
        )

    return transactions


def transform_all(tables: dict[str, pd.DataFrame]) -> dict[str, pd.DataFrame]:
    return {
        "customers": transform_customers(tables["customers"]),
        "products": transform_products(tables["products"]),
        "campaigns": transform_campaigns(tables["campaigns"]),
        "events": transform_events(tables["events"]),
        "transactions": transform_transactions(tables["transactions"]),
    }
