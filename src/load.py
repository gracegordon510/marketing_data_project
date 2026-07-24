"""Load transformed DataFrames into SQL Server."""

import pandas as pd
from sqlalchemy.engine import Engine


def load_dataframe(
    dataframe: pd.DataFrame,
    table_name: str,
    engine: Engine,
    chunksize: int = 10_000,
) -> None:
    """Append a DataFrame to an existing SQL Server table."""

    dataframe.to_sql(
        name=table_name,
        con=engine,
        schema="dbo",
        if_exists="append",
        index=False,
        chunksize=chunksize,
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