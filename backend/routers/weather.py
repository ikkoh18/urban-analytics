from fastapi import APIRouter, HTTPException, Query
from services import weather_service

router = APIRouter(prefix="/weather", tags=["weather"])


@router.get("/by-hour")
def by_hour():
    try:
        return {
            "temperature": weather_service.get_temperature_by_hour(),
            "precipitation": weather_service.get_precipitation_by_hour(),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/current")
def current(hour: int = Query(..., ge=0, le=23)):
    try:
        return weather_service.get_conditions_by_hour(hour)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/map")
def for_map(hour: int = Query(..., ge=0, le=23)):
    try:
        return weather_service.get_weather_for_map(hour)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
