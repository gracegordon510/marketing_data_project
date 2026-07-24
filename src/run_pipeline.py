"""Run the complete ETL pipeline."""

import logging

from src.database import create_database_engine
from src.extract import extract_all
from src.transform import transform_all
from src.validate import validate_all
from src.load import load_all


logger = logging.getLogger(__name__)

def run_pipeline() -> None:
    """Extract, transform, validate, and load all project data."""

    print("Extracting data...")
    raw_tables = extract_all()

    print("Transforming data...")
    transformed_tables = transform_all(raw_tables)

    print("Validating data...")
    validate_all(transformed_tables)

    print("Connecting to SQL Server...")
    engine = create_database_engine()

    print("Loading data...")
    load_all(transformed_tables, engine)

    print("Pipeline completed successfully.")


if __name__ == "__main__":
    try:
        run_pipeline()
    except Exception:
        logger.exception("Pipeline failed.")
        raise