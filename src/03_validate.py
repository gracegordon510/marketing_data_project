import logging

import pandas as pd

from typing import Any

logger = logging.getLogger(__name__)


# ---------------------------------------------------------
# General validation functions
# ---------------------------------------------------------


def validate_required_columns(
    df: pd.DataFrame,
    required_columns: list[str],
    table_name: str,
) -> None:
    """Check that all expected columns exist."""

    missing_columns = [
        column for column in required_columns if column not in df.columns
    ]

    if missing_columns:
        raise ValueError(f"{table_name} is missing columns: {missing_columns}")


def validate_primary_key(
    df: pd.DataFrame,
    primary_key: str,
    table_name: str,
) -> None:
    """Check that a primary key has no nulls or duplicates."""

    null_count = df[primary_key].isna().sum()

    if null_count > 0:
        raise ValueError(
            f"{table_name}.{primary_key} contains " f"{null_count:,} null values."
        )

    duplicate_count = df[primary_key].duplicated().sum()

    if duplicate_count > 0:
        raise ValueError(
            f"{table_name}.{primary_key} contains "
            f"{duplicate_count:,} duplicate values."
        )


def validate_not_null(
    df: pd.DataFrame,
    columns: list[str],
    table_name: str,
) -> None:
    """Check that required columns contain no nulls."""

    null_counts = df[columns].isna().sum()
    invalid_columns = null_counts[null_counts > 0]

    if not invalid_columns.empty:
        raise ValueError(f"{table_name} contains null values:\n" f"{invalid_columns}")


def validate_allowed_values(
    df: pd.DataFrame,
    column: str,
    allowed_values: set[Any],
    table_name: str,
    allow_null: bool = False,
) -> None:
    """Check that a column contains only approved values."""

    values = df[column]

    if allow_null:
        values = values.dropna()

    invalid_values = set(values.unique()) - allowed_values

    if invalid_values:
        raise ValueError(
            f"{table_name}.{column} contains invalid values: " f"{invalid_values}"
        )


def validate_numeric_range(
    df: pd.DataFrame,
    column: str,
    table_name: str,
    minimum: float | None = None,
    maximum: float | None = None,
    allow_null: bool = False,
) -> None:
    """Check that numeric values fall within an expected range."""

    values = df[column]

    if allow_null:
        values = values.dropna()

    invalid_mask = pd.Series(
        False,
        index=values.index,
    )

    if minimum is not None:
        invalid_mask |= values < minimum

    if maximum is not None:
        invalid_mask |= values > maximum

    invalid_count = invalid_mask.sum()

    if invalid_count > 0:
        raise ValueError(
            f"{table_name}.{column} contains "
            f"{invalid_count:,} values outside the expected range."
        )


def validate_datetime(
    df: pd.DataFrame,
    column: str,
    table_name: str,
) -> None:
    """Check that a column has a datetime data type."""

    if not pd.api.types.is_datetime64_any_dtype(df[column]):
        raise TypeError(
            f"{table_name}.{column} must be datetime. "
            f"Current dtype: {df[column].dtype}"
        )


def validate_foreign_key(
    child_df: pd.DataFrame,
    child_column: str,
    parent_df: pd.DataFrame,
    parent_column: str,
    child_table: str,
    parent_table: str,
    allow_null: bool = False,
    extra_valid_values: set[Any] | None = None,
) -> None:
    """Check that foreign-key values exist in the parent table."""

    child_values = child_df[child_column]

    if not allow_null and child_values.isna().any():
        raise ValueError(f"{child_table}.{child_column} contains null values.")

    valid_values = set(parent_df[parent_column].dropna())

    if extra_valid_values:
        valid_values.update(extra_valid_values)

    invalid_values = set(child_values.dropna()) - valid_values

    if invalid_values:
        raise ValueError(
            f"{child_table}.{child_column} contains values not found "
            f"in {parent_table}.{parent_column}: "
            f"{list(invalid_values)[:10]}"
        )


# ---------------------------------------------------------
# Table-specific validations
# ---------------------------------------------------------


def validate_customers(
    customers: pd.DataFrame,
) -> None:

    required_columns = [
        "customer_id",
        "signup_date",
        "country",
        "age",
        "gender",
        "loyalty_tier",
        "acquisition_channel",
    ]

    validate_required_columns(
        customers,
        required_columns,
        "customers",
    )

    validate_primary_key(
        customers,
        "customer_id",
        "customers",
    )

    validate_not_null(
        customers,
        required_columns,
        "customers",
    )

    validate_datetime(
        customers,
        "signup_date",
        "customers",
    )

    validate_numeric_range(
        customers,
        "age",
        "customers",
        minimum=0,
        maximum=150,
    )

    validate_allowed_values(
        customers,
        "gender",
        {"Male", "Female", "Other"},
        "customers",
    )

    validate_allowed_values(
        customers,
        "loyalty_tier",
        {"Bronze", "Silver", "Gold", "Platinum"},
        "customers",
    )

    validate_allowed_values(
        customers,
        "acquisition_channel",
        {
            "Referral",
            "Organic",
            "Paid Search",
            "Social",
            "Email",
        },
        "customers",
    )


def validate_products(
    products: pd.DataFrame,
) -> None:
    required_columns = [
        "product_id",
        "category",
        "brand",
        "base_price",
        "launch_date",
        "is_premium",
    ]

    validate_required_columns(
        products,
        required_columns,
        "products",
    )

    validate_primary_key(
        products,
        "product_id",
        "products",
    )

    validate_not_null(
        products,
        required_columns,
        "products",
    )

    validate_datetime(
        products,
        "launch_date",
        "products",
    )

    validate_numeric_range(
        products,
        "base_price",
        "products",
        minimum=0,
    )

    validate_allowed_values(
        products,
        "category",
        {
            "Electronics",
            "Fashion",
            "Home",
            "Grocery",
            "Sport",
            "Beauty",
        },
        "products",
    )


def validate_campaigns(
    campaigns: pd.DataFrame,
) -> None:
    required_columns = [
        "campaign_id",
        "channel",
        "objective",
        "target_segment",
        "start_date",
        "end_date",
        "expected_uplift",
    ]

    validate_required_columns(
        campaigns,
        required_columns,
        "campaigns",
    )

    validate_primary_key(
        campaigns,
        "campaign_id",
        "campaigns",
    )

    validate_not_null(
        campaigns,
        required_columns,
        "campaigns",
    )

    validate_datetime(
        campaigns,
        "start_date",
        "campaigns",
    )

    validate_datetime(
        campaigns,
        "end_date",
        "campaigns",
    )

    validate_numeric_range(
        campaigns,
        "expected_uplift",
        "campaigns",
        minimum=0,
        maximum=1,
    )

    invalid_dates = campaigns[campaigns["end_date"] < campaigns["start_date"]]

    if not invalid_dates.empty:
        raise ValueError(
            f"campaigns contains {len(invalid_dates):,} rows where "
            "end_date is before start_date."
        )


def validate_events(
    events: pd.DataFrame,
    customers: pd.DataFrame,
    products: pd.DataFrame,
    campaigns: pd.DataFrame,
) -> None:

    required_columns = [
        "event_id",
        "timestamp",
        "customer_id",
        "product_id",
        "campaign_id",
        "event_type",
        "device_type",
        "traffic_source",
        "session_id",
        "page_category",
        "session_duration_sec",
        "experiment_group",
    ]

    validate_required_columns(
        events,
        required_columns,
        "events",
    )

    validate_primary_key(
        events,
        "event_id",
        "events",
    )

    validate_not_null(
        events,
        [
            "event_id",
            "timestamp",
            "customer_id",
            "campaign_id",
            "event_type",
            "traffic_source",
            "session_id",
            "page_category",
            "session_duration_sec",
            "experiment_group",
        ],
        "events",
    )

    validate_datetime(
        events,
        "timestamp",
        "events",
    )

    validate_numeric_range(
        events,
        "session_duration_sec",
        "events",
        minimum=0,
    )

    validate_allowed_values(
        events,
        "event_type",
        {
            "view",
            "click",
            "add_to_cart",
            "bounce",
            "purchase",
        },
        "events",
    )

    validate_allowed_values(
        events,
        "device_type",
        {"desktop", "mobile", "tablet"},
        "events",
        allow_null=True,
    )

    validate_allowed_values(
        events,
        "traffic_source",
        {
            "Email",
            "Organic",
            "Paid Search",
            "Social",
            "Direct",
        },
        "events",
    )

    validate_foreign_key(
        events,
        "customer_id",
        customers,
        "customer_id",
        "events",
        "customers",
    )

    validate_foreign_key(
        events,
        "product_id",
        products,
        "product_id",
        "events",
        "products",
        allow_null=True,
    )

    validate_foreign_key(
        events,
        "campaign_id",
        campaigns,
        "campaign_id",
        "events",
        "campaigns",
        extra_valid_values={0},
    )


def validate_transactions(
    transactions: pd.DataFrame,
    customers: pd.DataFrame,
    products: pd.DataFrame,
    campaigns: pd.DataFrame,
) -> None:

    required_columns = [
        "transaction_id",
        "timestamp",
        "customer_id",
        "product_id",
        "quantity",
        "discount_applied",
        "gross_revenue",
        "campaign_id",
        "refund_flag",
    ]

    validate_required_columns(
        transactions,
        required_columns,
        "transactions",
    )

    validate_primary_key(
        transactions,
        "transaction_id",
        "transactions",
    )

    validate_not_null(
        transactions,
        required_columns,
        "transactions",
    )

    validate_datetime(
        transactions,
        "timestamp",
        "transactions",
    )

    validate_numeric_range(
        transactions,
        "quantity",
        "transactions",
        minimum=1,
    )

    validate_numeric_range(
        transactions,
        "discount_applied",
        "transactions",
        minimum=0,
        maximum=1,
    )

    validate_allowed_values(
        transactions,
        "refund_flag",
        {True, False},
        "transactions",
    )

    validate_foreign_key(
        transactions,
        "customer_id",
        customers,
        "customer_id",
        "transactions",
        "customers",
    )

    validate_foreign_key(
        transactions,
        "product_id",
        products,
        "product_id",
        "transactions",
        "products",
    )

    validate_foreign_key(
        transactions,
        "campaign_id",
        campaigns,
        "campaign_id",
        "transactions",
        "campaigns",
        extra_valid_values={0},
    )


# ---------------------------------------------------------
# Known dataset limitations
# ---------------------------------------------------------


def report_campaign_timing_issues(
    facts: pd.DataFrame,
    campaigns: pd.DataFrame,
    table_name: str,
) -> None:
    """
    Log the percentage of campaign-linked rows outside campaign dates.

    This does not stop the pipeline because it is a known limitation
    of the synthetic dataset.
    """

    attributed_rows = facts[facts["campaign_id"].ne(0)]

    merged = attributed_rows.merge(
        campaigns[
            [
                "campaign_id",
                "start_date",
                "end_date",
            ]
        ],
        on="campaign_id",
        how="left",
    )

    outside_campaign = (merged["timestamp"] < merged["start_date"]) | (
        merged["timestamp"] > merged["end_date"]
    )

    invalid_count = outside_campaign.sum()
    total_count = len(merged)

    percentage = invalid_count / total_count * 100 if total_count > 0 else 0

    logger.warning(
        "%s: %.2f%% of campaign-linked rows fall outside " "the campaign date range.",
        table_name,
        percentage,
    )


# ---------------------------------------------------------
# Run all validations
# ---------------------------------------------------------


def validate_all(
    tables: dict[str, pd.DataFrame],
) -> None:
    """Run all table and relationship validations."""

    required_tables = {
        "customers",
        "products",
        "campaigns",
        "events",
        "transactions",
    }

    missing_tables = required_tables - set(tables)

    if missing_tables:
        raise ValueError(f"Missing required tables: {missing_tables}")

    customers = tables["customers"]
    products = tables["products"]
    campaigns = tables["campaigns"]
    events = tables["events"]
    transactions = tables["transactions"]

    logger.info("Validating customers.")
    validate_customers(customers)

    logger.info("Validating products.")
    validate_products(products)

    logger.info("Validating campaigns.")
    validate_campaigns(campaigns)

    logger.info("Validating events.")
    validate_events(
        events,
        customers,
        products,
        campaigns,
    )

    logger.info("Validating transactions.")
    validate_transactions(
        transactions,
        customers,
        products,
        campaigns,
    )

    report_campaign_timing_issues(
        events,
        campaigns,
        "events",
    )

    report_campaign_timing_issues(
        transactions,
        campaigns,
        "transactions",
    )

    logger.info("All hard validations passed.")
