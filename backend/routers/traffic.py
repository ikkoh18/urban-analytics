from fastapi import APIRouter, HTTPException, Query
from services import traffic_service

router = APIRouter(prefix="/traffic", tags=["traffic"])


@router.get("/segments")
def segments(hour: int = Query(..., ge=0, le=23)):
    try:
        return traffic_service.get_segments_by_hour(hour)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/speed-by-hour")
def speed_by_hour():
    try:
        return traffic_service.get_speed_by_hour()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/flow-by-hour")
def flow_by_hour():
    try:
        return traffic_service.get_flow_by_hour()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
