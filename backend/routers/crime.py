from fastapi import APIRouter, HTTPException, Query
from services import crime_service

router = APIRouter(prefix="/crime", tags=["crime"])


@router.get("/heatmap")
def heatmap(hour: int = Query(..., ge=0, le=23),
            day_of_week: str | None = Query(None)):
    try:
        return crime_service.get_heatmap_points(hour, day_of_week)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/heatmap/tile")
def heatmap_tile(
    hour:    int   = Query(..., ge=0, le=23),
    lat_min: float = Query(...),
    lat_max: float = Query(...),
    lon_min: float = Query(...),
    lon_max: float = Query(...),
):
    try:
        return crime_service.get_heatmap_tile(hour, lat_min, lat_max, lon_min, lon_max)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/by-hour")
def by_hour():
    try:
        return crime_service.get_crime_by_hour()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/by-area")
def by_area():
    try:
        return crime_service.get_crime_by_area()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/risk")
def risk(area: str = Query(...), hour: int = Query(..., ge=0, le=23)):
    try:
        return crime_service.get_risk_level(area, hour)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
