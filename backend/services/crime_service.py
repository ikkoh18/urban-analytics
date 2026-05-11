import pandas as pd
import numpy as np
from config import CRIME_CLEAN_CSV

# Carregamento único na inicialização — filtra 2022 em diante
_df: pd.DataFrame = pd.read_csv(CRIME_CLEAN_CSV)
_df["timestamp"] = pd.to_datetime(_df["timestamp"], errors="coerce")
_df = _df.dropna(subset=["timestamp"])
_df = _df[_df["timestamp"].dt.year >= 2022].copy()
_df["hour"] = _df["timestamp"].dt.hour
_df["date"] = _df["timestamp"].dt.date

# Percentis globais por (date, hour) para classificação de risco
_global_counts = _df.groupby(["date", "hour"]).size()
_P33 = float(_global_counts.quantile(0.33))
_P66 = float(_global_counts.quantile(0.66))

# Máximo de crimes diários por hora de qualquer área — usado na normalização
_area_daily = (
    _df.groupby(["area_name", "date", "hour"])
    .size()
    .reset_index(name="cnt")
)
_CRIME_MAX = float(_area_daily["cnt"].max()) if not _area_daily.empty else 1.0


def get_heatmap_points(hour: int, day_of_week: str | None = None) -> list[dict]:
    """Retorna até 800 pontos de heatmap normalizados para o horário dado."""
    mask = _df["hour"] == hour
    sub = _df[mask]

    if day_of_week:
        dow_map = {
            "monday": 0, "tuesday": 1, "wednesday": 2,
            "thursday": 3, "friday": 4, "saturday": 5, "sunday": 6,
        }
        dow = dow_map.get(day_of_week.lower())
        if dow is not None:
            sub = sub[sub["timestamp"].dt.dayofweek == dow]

    if sub.empty:
        return []

    sub = sub.dropna(subset=["lat", "lon"])
    sub = sub[(sub["lat"] != 0) & (sub["lon"] != 0)]

    grouped = (
        sub.assign(lat_r=sub["lat"].round(2), lon_r=sub["lon"].round(2))
        .groupby(["lat_r", "lon_r"])
        .size()
        .reset_index(name="count")
    )

    max_count = grouped["count"].max()
    grouped["weight"] = grouped["count"] / max_count
    grouped = grouped[grouped["weight"] >= 0.008]
    grouped = grouped.nlargest(1500, "weight")

    return [
        {"lat": row.lat_r, "lon": row.lon_r, "weight": round(row.weight, 4)}
        for row in grouped.itertuples()
    ]


def get_crime_by_hour() -> list[float]:
    """Média de ocorrências por hora do dia (0-23)."""
    daily_by_hour = _df.groupby(["date", "hour"]).size().reset_index(name="cnt")
    hourly_avg = daily_by_hour.groupby("hour")["cnt"].mean()
    hourly_avg = hourly_avg.reindex(range(24), fill_value=0.0)
    return [round(float(v), 2) for v in hourly_avg]


def get_crime_by_area() -> list[dict]:
    """Top 10 bairros por total de ocorrências."""
    by_area = _df.groupby("area_name").size().reset_index(name="total")
    by_area = by_area.nlargest(10, "total")
    return [{"name": row.area_name, "total": int(row.total)} for row in by_area.itertuples()]


def get_risk_level(area_name: str, hour: int) -> dict:
    """Nível de risco (low/medium/high) para uma área + horário."""
    sub = _df[(_df["area_name"] == area_name) & (_df["hour"] == hour)]
    if sub.empty:
        return {"level": "low", "avg_count": 0.0}

    daily_counts = sub.groupby("date").size()
    avg_count = float(daily_counts.mean())

    if avg_count >= _P66:
        level = "high"
    elif avg_count >= _P33:
        level = "medium"
    else:
        level = "low"

    return {"level": level, "avg_count": round(avg_count, 2)}


def get_areas() -> list[str]:
    """Lista de todas as áreas disponíveis no dataset."""
    return sorted(_df["area_name"].dropna().unique().tolist())


def get_crime_norm_for_area_hour(area_name: str, hour: int) -> float:
    """Crime normalizado 0-1 para uso no risk_service."""
    sub = _df[(_df["area_name"] == area_name) & (_df["hour"] == hour)]
    if sub.empty:
        return 0.0
    avg = float(sub.groupby("date").size().mean())
    return min(avg / _CRIME_MAX, 1.0)
