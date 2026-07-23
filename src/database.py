from urllib.parse import quote_plus

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine

from config import SQL_DATABASE, SQL_DRIVER, SQL_SERVER


def create_database_engine() -> Engine:
    """Create a SQLAlchemy engine using Windows Authentication."""

    odbc_connection_string = (
        f"DRIVER={{{SQL_DRIVER}}};"
        f"SERVER={SQL_SERVER};"
        f"DATABASE={SQL_DATABASE};"
        "Trusted_Connection=yes;"
        "Encrypt=yes;"
        "TrustServerCertificate=yes;"
    )

    encoded_connection_string = quote_plus(odbc_connection_string)

    return create_engine(
        f"mssql+pyodbc:///?odbc_connect={encoded_connection_string}"
    )


