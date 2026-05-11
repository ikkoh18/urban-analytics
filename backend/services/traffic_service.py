"""
Traffic service.

Geometria das vias: chama API OSRM pública na inicialização para obter
os pontos reais de cada rota. Fallback para pontos hardcoded se OSRM
estiver indisponível. O resultado é cacheado em memória — sem chamada
de rede a cada requisição.

Velocidades: urban_dataset_2025.csv (startup rápido) + cache por rota
das 3 freeways (I-10/I-101/I-110) gerado em background a partir do
traffic_2025_core.csv.
"""

import json
import threading
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import pandas as pd
from config import URBAN_DATASET_CSV, TRAFFIC_CORE_CSV

# ── Carregamento rápido — urban_dataset_2025.csv ─────────────────────────────
_urban_df: pd.DataFrame = pd.read_csv(URBAN_DATASET_CSV)
_urban_df["timestamp"] = pd.to_datetime(_urban_df["timestamp"], errors="coerce")
_urban_df = _urban_df.dropna(subset=["avg_speed", "timestamp"]).copy()
_urban_df["hour"] = _urban_df["timestamp"].dt.hour

_freeway_speed_by_hour: dict[int, float] = (
    _urban_df.groupby("hour")["avg_speed"]
    .mean()
    .reindex(range(24), fill_value=55.0)
    .to_dict()
)
_FREEWAY_BASELINE = float(_urban_df["avg_speed"].median()) or 55.0

# ── Cache de velocidade por rota (freeways) ──────────────────────────────────
_CACHE_PATH = Path(TRAFFIC_CORE_CSV).parent / "traffic_hourly_cache.csv"
_route_speed_by_hour: dict[int, dict[int, float]] = {}


def _build_route_cache() -> None:
    try:
        df = pd.read_csv(
            TRAFFIC_CORE_CSV,
            usecols=["timestamp", "route", "avg_speed"],
            dtype={"route": "int32", "avg_speed": "float32"},
        )
        df["timestamp"] = pd.to_datetime(df["timestamp"], errors="coerce")
        df = df.dropna(subset=["avg_speed", "timestamp"])
        df["hour"] = df["timestamp"].dt.hour
        agg = (
            df[df["route"].isin([10, 101, 110])]
            .groupby(["route", "hour"])["avg_speed"]
            .mean()
            .reset_index()
        )
        agg.to_csv(_CACHE_PATH, index=False)
        for _, row in agg.iterrows():
            h, r = int(row["hour"]), int(row["route"])
            _route_speed_by_hour.setdefault(h, {})[r] = float(row["avg_speed"])
    except Exception as e:
        print(f"[traffic_service] cache build failed: {e}")


def _init_route_cache() -> None:
    if _CACHE_PATH.exists():
        try:
            df = pd.read_csv(_CACHE_PATH)
            for _, row in df.iterrows():
                h, r = int(row["hour"]), int(row["route"])
                _route_speed_by_hour.setdefault(h, {})[r] = float(row["avg_speed"])
            return
        except Exception:
            pass
    threading.Thread(target=_build_route_cache, daemon=True).start()


_init_route_cache()

# ── Geometria via OSRM ────────────────────────────────────────────────────────
_OSRM_BASE = "http://router.project-osrm.org/route/v1/driving"

# Pontos hardcoded de fallback por rota (usados se OSRM falhar)
_FALLBACK_POINTS: dict[str, list[list[float]]] = {
    "Hollywood Blvd": [
        [34.1016, -118.3398], [34.1007, -118.3272], [34.0993, -118.3195],
        [34.0984, -118.3101], [34.0974, -118.3017], [34.0966, -118.2943],
    ],
    "Sunset Blvd": [
        [34.0881, -118.2968], [34.0869, -118.2901], [34.0858, -118.2836],
        [34.0847, -118.2779], [34.0836, -118.2697], [34.0820, -118.3200],
        [34.0800, -118.3876],
    ],
    "Santa Monica Blvd": [
        [34.0905, -118.3272], [34.0903, -118.3360], [34.0902, -118.3447],
        [34.0901, -118.3534], [34.0900, -118.3621], [34.0490, -118.4200],
        [34.0170, -118.4911],
    ],
    "I-101 Hollywood Fwy": [
        [34.1013, -118.3398], [34.0897, -118.3287], [34.0784, -118.3013],
        [34.0671, -118.2836], [34.0558, -118.2694], [34.0518, -118.2568],
    ],
    "I-110 Harbor Fwy": [
        [34.0558, -118.2568], [34.0231, -118.2606], [33.9981, -118.2683],
        [33.9731, -118.2761], [33.9358, -118.2761],
    ],
    "I-10 Santa Monica Fwy": [
        [34.0407, -118.2468], [34.0363, -118.2764], [34.0319, -118.3230],
        [34.0275, -118.3791], [34.0231, -118.4352], [34.0184, -118.4912],
    ],
    "Wilshire Blvd": [
        [34.0558, -118.2900], [34.0585, -118.3126], [34.0630, -118.3576],
        [34.0621, -118.3863], [34.0612, -118.4150], [34.0603, -118.4437],
    ],
    "Vermont Ave": [
        [34.1013, -118.2919], [34.0784, -118.2919],
        [34.0558, -118.2919], [34.0275, -118.2919],
    ],
}

# Configuração de cada via: origem, destino, número de rota PeMS, velocidade base
_ROUTES_CONFIG: list[dict] = [
    {"name": "Hollywood Blvd",     "route": None, "base_speed": 22.0,
     "origin": (34.1016, -118.3398), "dest": (34.0966, -118.2943)},
    {"name": "Sunset Blvd",        "route": None, "base_speed": 28.0,
     "origin": (34.0881, -118.2968), "dest": (34.0774, -118.3876)},
    {"name": "Santa Monica Blvd",  "route": None, "base_speed": 40.0,
     "origin": (34.0905, -118.3272), "dest": (34.0170, -118.4911)},
    {"name": "I-101 Hollywood Fwy","route": 101,  "base_speed": 55.0,
     "origin": (34.1013, -118.3398), "dest": (34.0518, -118.2568)},
    {"name": "I-110 Harbor Fwy",   "route": 110,  "base_speed": 55.0,
     "origin": (34.0558, -118.2568), "dest": (33.8958, -118.2761)},
    {"name": "I-10 Santa Monica Fwy","route": 10, "base_speed": 55.0,
     "origin": (34.0407, -118.2468), "dest": (34.0184, -118.4912)},
    {"name": "Wilshire Blvd",      "route": None, "base_speed": 28.0,
     "origin": (34.0558, -118.2900), "dest": (34.0603, -118.4437)},
    {"name": "Vermont Ave",        "route": None, "base_speed": 35.0,
     "origin": (34.1013, -118.2919), "dest": (34.0275, -118.2919)},
]

# Geometria real das vias (preenchida na inicialização)
_SEGMENTS: list[dict] = []


def _fetch_osrm_geometry(name: str, origin: tuple, dest: tuple) -> list[list[float]] | None:
    """Chama OSRM e retorna lista de [lat, lon] da rota real."""
    url = (
        f"{_OSRM_BASE}/{origin[1]},{origin[0]};{dest[1]},{dest[0]}"
        f"?overview=full&geometries=geojson"
    )
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "UrbanAnalyticsApp/1.0"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read())
        coords = data["routes"][0]["geometry"]["coordinates"]
        # OSRM retorna [lon, lat] — inverte para [lat, lon]
        return [[pt[1], pt[0]] for pt in coords]
    except Exception as e:
        print(f"[traffic_service] OSRM failed for {name}: {e}")
        return None


def _init_geometry() -> None:
    """Busca geometrias OSRM em paralelo na inicialização."""
    def fetch_one(cfg: dict) -> tuple[str, list]:
        pts = _fetch_osrm_geometry(cfg["name"], cfg["origin"], cfg["dest"])
        return cfg["name"], pts or _FALLBACK_POINTS[cfg["name"]]

    # Até 4 workers paralelos — respeita rate limit da API pública
    with ThreadPoolExecutor(max_workers=4) as ex:
        futures = {ex.submit(fetch_one, cfg): cfg for cfg in _ROUTES_CONFIG}
        name_to_points: dict[str, list] = {}
        for fut in as_completed(futures):
            name, pts = fut.result()
            name_to_points[name] = pts

    for cfg in _ROUTES_CONFIG:
        _SEGMENTS.append({
            "name":       cfg["name"],
            "route":      cfg["route"],
            "base_speed": cfg["base_speed"],
            "points":     name_to_points.get(cfg["name"], _FALLBACK_POINTS[cfg["name"]]),
        })

    sources = {
        cfg["name"]: ("osrm" if name_to_points.get(cfg["name"]) is not None else "fallback")
        for cfg in _ROUTES_CONFIG
    }
    print(f"[traffic_service] geometrias carregadas: {sources}")


_init_geometry()


# ── Funções públicas ─────────────────────────────────────────────────────────

def _congestion_ratio(hour: int) -> float:
    observed = _freeway_speed_by_hour.get(hour, _FREEWAY_BASELINE)
    return min(observed / _FREEWAY_BASELINE, 1.0)


def _speed_to_color(speed: float) -> str:
    if speed < 40:
        return "red"
    if speed < 55:
        return "orange"
    return "blue"


def get_segments_by_hour(hour: int) -> list[dict]:
    """Retorna segmentos com geometria real (OSRM) e velocidade real (PeMS)."""
    ratio = _congestion_ratio(hour)
    result = []
    for seg in _SEGMENTS:
        route = seg["route"]
        if (
            route is not None
            and hour in _route_speed_by_hour
            and route in _route_speed_by_hour[hour]
        ):
            avg_speed = _route_speed_by_hour[hour][route]
        else:
            avg_speed = seg["base_speed"] * ratio
        avg_speed = round(avg_speed, 1)
        result.append({
            "name":      seg["name"],
            "points":    seg["points"],
            "avg_speed": avg_speed,
            "color":     _speed_to_color(avg_speed),
        })
    return result


def get_speed_by_hour() -> list[float]:
    return [round(_freeway_speed_by_hour.get(h, 0.0), 2) for h in range(24)]


def get_flow_by_hour() -> list[float]:
    flow = (
        _urban_df.groupby("hour")["traffic_flow"]
        .mean()
        .reindex(range(24), fill_value=0.0)
    )
    max_flow = float(flow.max()) or 1.0
    return [round(float(v) / max_flow, 4) for v in flow]
