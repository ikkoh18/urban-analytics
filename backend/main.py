import pandas as pd
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import CRIME_CLEAN_CSV, URBAN_DATASET_CSV, TRAFFIC_CORE_CSV, WEATHER_CSV
from routers import crime, traffic, weather, risk

app = FastAPI(title="Urban Analytics API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(crime.router)
app.include_router(traffic.router)
app.include_router(weather.router)
app.include_router(risk.router)


@app.get("/")
def root():
    return {"status": "ok", "message": "Urban Analytics API rodando"}


@app.get("/health")
def health():
    """Valida carregamento dos três datasets."""
    results = {}

    for label, path in [
        ("crime", CRIME_CLEAN_CSV),
        ("urban_dataset", URBAN_DATASET_CSV),
        ("traffic_core", TRAFFIC_CORE_CSV),
        ("weather", WEATHER_CSV),
    ]:
        try:
            df = pd.read_csv(path, nrows=0)  # só lê header
            full = pd.read_csv(path)
            results[label] = {
                "path": str(path),
                "rows": len(full),
                "columns": list(full.columns),
                "nulls": full.isnull().sum().to_dict(),
            }
        except Exception as e:
            results[label] = {"error": str(e), "path": str(path)}

    return results
