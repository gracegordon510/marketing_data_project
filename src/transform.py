import logging
import pandas as pd

logger = logging.getLogger("marketing_etl")


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

    events["device_type"] = events["device_type"].str.strip().str.title()

    events["page_category"] = events["page_category"].str.strip().str.upper()

    events["experiment_group"] = events["experiment_group"].str.strip()

    events["event_id"] = events["event_id"].astype("Int64")
    events["customer_id"] = events["customer_id"].astype("Int64")
    events["product_id"] = events["product_id"].astype("Int64")
    events["campaign_id"] = events["campaign_id"].astype("Int64")

    invalid_purchase_events = (
        events["event_type"].eq("purchase") & events["product_id"].isna()
    )

    removed_purchase_event_count = invalid_purchase_events.sum()

    events = events.loc[~invalid_purchase_events].copy()

    logger.info(
        "Removed %s purchase events with missing product_id.",
        f"{removed_purchase_event_count:,}",
    )

    return events


def transform_transactions(
    df_transactions: pd.DataFrame, df_products: pd.DataFrame
) -> pd.DataFrame:
    transactions = df_transactions.copy()
    products = df_products.copy()

    transactions.rename(
        columns={"timestamp": "transaction_timestamp"},
        inplace=True,
    )

    transactions = transactions.rename(columns={"gross_revenue": "transaction_amount"})

    transactions["transaction_timestamp"] = pd.to_datetime(
        transactions["transaction_timestamp"], errors="coerce"
    )

    transactions["quantity"] = pd.to_numeric(
        transactions["quantity"], errors="coerce"
    ).astype("Int64")

    transactions["discount_applied"] = pd.to_numeric(
        transactions["discount_applied"], errors="coerce"
    )

    transactions["transaction_amount"] = pd.to_numeric(
        transactions["transaction_amount"], errors="coerce"
    )

    transactions["refund_flag"] = transactions["refund_flag"].astype("boolean")

    transactions["transaction_id"] = transactions["transaction_id"].astype("Int64")
    transactions["customer_id"] = transactions["customer_id"].astype("Int64")
    transactions["product_id"] = transactions["product_id"].astype("Int64")
    transactions["campaign_id"] = transactions["campaign_id"].astype("Int64")

    unusable_rows = (
        transactions["product_id"].isna() | transactions["transaction_amount"].isna()
    )

    removed_count = unusable_rows.sum()
    original_count = len(transactions)

    removed_percentage = (
        removed_count / original_count * 100 if original_count > 0 else 0
    )

    transactions = transactions.loc[~unusable_rows].copy()

    logger.info(
        "Removed %s unusable transaction rows (%.2f%% of source transactions).",
        f"{removed_count:,}",
        removed_percentage,
    )

    # Add product price temporarily
    transactions = transactions.merge(
        products[["product_id", "base_price"]],
        on="product_id",
        how="left",
        validate="many_to_one",
    )

    # Original value before discounts and refunds
    transactions["gross_revenue"] = (
        transactions["quantity"] * transactions["base_price"]
    ).round(2)

    # Price is already stored in dim_products
    transactions = transactions.drop(columns=["base_price"])

    return transactions


def transform_all(tables: dict[str, pd.DataFrame]) -> dict[str, pd.DataFrame]:

    transformed_tables = {
        "customers": transform_customers(tables["customers"]),
        "products": transform_products(tables["products"]),
        "campaigns": transform_campaigns(tables["campaigns"]),
        "events": transform_events(tables["events"]),
        "transactions": transform_transactions(
            tables["transactions"],
            tables["products"],
        ),
    }

    for table_name, df in transformed_tables.items():
        logger.info(
            "Transformed %s: %s rows, %s columns.",
            table_name,
            f"{len(df):,}",
            len(df.columns),
        )

    return transformed_tables
