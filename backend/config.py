from pathlib import Path

# Raiz do repositório (dois níveis acima de config.py)
_ROOT = Path(__file__).parent.parent

CRIME_CLEAN_CSV   = _ROOT / "data" / "processed" / "crime" / "crime_2020_2025_clean.csv"
URBAN_DATASET_CSV = _ROOT / "data" / "processed" / "urban_dataset_2025.csv"
TRAFFIC_CORE_CSV  = _ROOT / "data" / "processed" / "traffic" / "traffic_2025_core.csv"
WEATHER_CSV       = _ROOT / "data" / "processed" / "weather" / "weather_2020_2025_clean.csv"
PEMS_RAW_DIR      = _ROOT / "data" / "raw" / "traffic"
