from pathlib import Path
import os
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parents[2]

DATA_RAW_DIR = BASE_DIR / "data" / "raw"
CRIME_DATA_DIR = DATA_RAW_DIR / "crime"

CRIME_API_URL = os.getenv("CRIME_API_URL")
CRIME_API_LIMIT = int(os.getenv("CRIME_API_LIMIT", 50000))
