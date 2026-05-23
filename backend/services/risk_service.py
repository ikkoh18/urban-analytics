from services import crime_service, traffic_service, weather_service

_MAX_PRECIP = 10.0  # mm — normalização da precipitação
_FREEWAY_MAX = 70.0  # mph — velocidade máxima esperada


def _compute_score(area_name: str, hour: int,
                   speed_array: list[float],
                   precip_array: list[float]) -> dict:
    crime_norm = crime_service.get_crime_norm_for_area_hour(area_name, hour)

    avg_speed = speed_array[hour]
    speed_norm = 1.0 - min(avg_speed / _FREEWAY_MAX, 1.0)  # lento = maior risco

    precip = precip_array[hour]
    precip_norm = min(precip / _MAX_PRECIP, 1.0)
    # Precipitação acima de 2 mm adiciona penalidade de 20%
    weather_norm = precip_norm + (0.2 if precip > 2.0 else 0.0)
    weather_norm = min(weather_norm, 1.0)

    raw = crime_norm * 0.5 + speed_norm * 0.3 + weather_norm * 0.2
    score = round(raw * 10, 2)
    level = "high" if score >= 6.0 else ("medium" if score >= 3.5 else "low")

    return {
        "area_name": area_name,
        "hour": hour,
        "score": score,
        "risk_level": level,
        "crime_norm": round(crime_norm, 4),
        "congestion_norm": round(speed_norm, 4),
        "weather_norm": round(weather_norm, 4),
    }


def get_risk_score(area_name: str, hour: int) -> dict:
    speed_array = traffic_service.get_speed_by_hour()
    precip_array = weather_service.get_precipitation_by_hour()
    return _compute_score(area_name, hour, speed_array, precip_array)


def get_top_risk_slots() -> list[dict]:
    """Top 10 combinações (área, hora) por score de risco."""
    speed_array = traffic_service.get_speed_by_hour()
    precip_array = weather_service.get_precipitation_by_hour()
    areas = crime_service.get_areas()

    results = []
    for area in areas:
        for hour in range(24):
            d = _compute_score(area, hour, speed_array, precip_array)
            results.append({"area": d["area_name"], "hour": d["hour"], "score": d["score"]})

    results.sort(key=lambda x: -x["score"])
    return results[:10]


def get_risk_ranking() -> list[dict]:
    """Ranking de bairros por score médio ao longo de todas as horas."""
    speed_array = traffic_service.get_speed_by_hour()
    precip_array = weather_service.get_precipitation_by_hour()
    areas = crime_service.get_areas()

    ranking = []
    for area in areas:
        scores = [
            _compute_score(area, h, speed_array, precip_array)["score"]
            for h in range(24)
        ]
        avg = round(sum(scores) / len(scores), 2)
        level = "high" if avg >= 6.0 else ("medium" if avg >= 3.5 else "low")
        ranking.append({"name": area, "avg_score": avg, "risk_level": level})

    ranking.sort(key=lambda x: -x["avg_score"])
    return ranking
