"""Load transformed DataFrames into SQL Server."""

import logging
from time import perf_counter

import pandas as pd
from sqlalchemy.engine import Engine

logger = logging.getLogger("marketing_etl")


def load_dataframe(
    dataframe: pd.DataFrame,
    table_name: str,
    engine: Engine,
    chunksize: int = 10_000,
) -> None:
    """Append a DataFrame to an existing SQL Server table."""

    row_count = len(dataframe)
    start_time = perf_counter()

    logger.info(
        "Loading %s rows into %s...",
        f"{row_count:,}",
        table_name,
    )

    dataframe.to_sql(
        name=table_name,
        con=engine,
        schema="dbo",
        if_exists="append",
        index=False,
        chunksize=chunksize,
    )

    elapsed_time = perf_counter() - start_time

    logger.info(
        "Loaded %s rows into %s successfully in %.2f seconds.",
        f"{row_count:,}",
        table_name,
        elapsed_time,
    )


def load_all(
    tables: dict[str, pd.DataFrame],
    engine: Engine,
) -> None:
    """Load all transformed tables in dependency order."""

    load_dataframe(tables["customers"], "dim_customers", engine)
    load_dataframe(tables["products"], "dim_products", engine)
    load_dataframe(tables["campaigns"], "dim_campaigns", engine)

    load_dataframe(tables["transactions"], "fact_transactions", engine)
    load_dataframe(tables["events"], "fact_events", engine)
