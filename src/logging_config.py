import logging
from src.config import PROJECT_ROOT

# Logging paths
LOG_DIR = PROJECT_ROOT / "logs"
LOG_FILE = LOG_DIR / "etl_pipeline.log"


def setup_logger():
    # Create logs directory if it does not exist
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    # Create/get logger
    logger = logging.getLogger("marketing_etl")
    logger.setLevel(logging.INFO)

    # Prevent duplicate handlers
    if logger.handlers:
        return logger

    # Define log message format
    formatter = logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")

    # File handler
    file_handler = logging.FileHandler(LOG_FILE)
    file_handler.setFormatter(formatter)

    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)

    # Add handlers
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    return logger
