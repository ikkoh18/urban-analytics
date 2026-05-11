import pandas as pd
from config import WEATHER_CSV

# Histórico 2020-2025 para médias horárias mais representativas
_df: pd.DataFrame = pd.read_csv(WEATHER_CSV)
_df["timestamp"] = pd.to_datetime(_df["timestamp"], errors="coerce")
_df = _df.dropna(subset=["temperature", "timestamp"]).copy()
_df["precipitation"] = _df["precipitation"].fillna(0.0)
_df["hour"] = _df["timestamp"].dt.hour

# Pré-computa médias por hora
_temp_by_hour: pd.Series = (
    _df.groupby("hour")["temperature"].mean().reindex(range(24), fill_value=20.0)
)
_precip_by_hour: pd.Series = (
    _df.groupby("hour")["precipitation"].mean().reindex(range(24), fill_value=0.0)
)


def get_conditions_by_hour(hour: int) -> dict:
    """Temperatura e precipitação médias para o horário dado."""
    return {
        "hour": hour,
        "temperature": round(float(_temp_by_hour.get(hour, 20.0)), 2),
        "precipitation": round(float(_precip_by_hour.get(hour, 0.0)), 4),
    }


def get_precipitation_by_hour() -> list[float]:
    """Precipitação média por hora (0-23)."""
    return [round(float(v), 4) for v in _precip_by_hour]


def get_temperature_by_hour() -> list[float]:
    """Temperatura média por hora (0-23)."""
    return [round(float(v), 2) for v in _temp_by_hour]


def get_weather_for_map(hour: int) -> dict:
    """Resumo para o app decidir ícone de chuva ou sol no mapa."""
    precip = float(_precip_by_hour.get(hour, 0.0))
    return {
        "hour": hour,
        "has_rain": precip > 0.5,
        "precipitation_mm": round(precip, 4),
    }
