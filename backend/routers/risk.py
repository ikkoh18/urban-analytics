from fastapi import APIRouter, HTTPException, Query
from services import risk_service

router = APIRouter(prefix="/risk", tags=["risk"])


@router.get("/score")
def score(area: str = Query(...), hour: int = Query(..., ge=0, le=23)):
    try:
        return risk_service.get_risk_score(area, hour)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/top-slots")
def top_slots():
    try:
        return risk_service.get_top_risk_slots()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/ranking")
def ranking():
    try:
        return risk_service.get_risk_ranking()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
