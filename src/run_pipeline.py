"""Run the complete ETL pipeline."""

from src.logging_config import setup_logger
from src.database import create_database_engine, test_database_connection
from src.extract import extract_all
from src.transform import transform_all
from src.validate import validate_all
from src.load import load_all
from time import perf_counter

logger = setup_logger()


def run_pipeline() -> None:
    """Extract, transform, validate, and load all project data."""

    start_time = perf_counter()

    logger.info("ETL pipeline started")

    logger.info("Extracting data...")
    raw_tables = extract_all()
    logger.info("Data extraction completed.")

    logger.info("Transforming data...")
    transformed_tables = transform_all(raw_tables)
    logger.info("Data transformation completed.")

    logger.info("Validating data...")
    validate_all(transformed_tables)
    logger.info("Data validation completed.")

    logger.info("Connecting to SQL Server...")
    engine = create_database_engine()
    test_database_connection(engine)
    logger.info("Database connection established.")

    logger.info("Loading data...")
    load_all(transformed_tables, engine)
    logger.info("Data loading completed.")

    elapsed_time = perf_counter() - start_time

    logger.info("ETL pipeline completed successfully in %.2f seconds.", elapsed_time)


if __name__ == "__main__":
    try:
        run_pipeline()
    except Exception:
        logger.exception("Pipeline failed.")
        raise
