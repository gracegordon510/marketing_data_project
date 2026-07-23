import os
from pathlib import Path

from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parent.parent
ENV_PATH = PROJECT_ROOT / ".env"

load_dotenv(ENV_PATH)

SQL_SERVER = os.getenv("SQL_SERVER")
SQL_DATABASE = os.getenv("SQL_DATABASE")
SQL_DRIVER = os.getenv("SQL_DRIVER")


def validate_config() -> None:
    required_variables = {
        "SQL_SERVER": SQL_SERVER,
        "SQL_DATABASE": SQL_DATABASE,
        "SQL_DRIVER": SQL_DRIVER,
    }

    missing_variables = [
        name for name, value in required_variables.items() if not value
    ]

    if missing_variables:
        missing = ", ".join(missing_variables)
        raise ValueError(f"Missing environment variables: {missing}")


validate_config()