from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
from app.services.score_service import score_service
from app.services.crash_service import crash_service

router = APIRouter()

class GpsPoint(BaseModel):
    latitude: float
    longitude: float
    speed: float
    heading: float
    altitude: Optional[float] = None
    timestamp: str

class TelemetryEvent(BaseModel):
    eventType: Optional[str] = None
    event_type: Optional[str] = None
    severity: Optional[str] = None
    timestamp: str
    sensor_values: Optional[Any] = None

class TripEvaluationRequest(BaseModel):
    trip_id: str
    points: List[GpsPoint]
    events: List[TelemetryEvent]

class CrashSummaryRequest(BaseModel):
    crash_report_id: str
    sensor_values: Dict[str, Any]

@router.post("/evaluate-trip")
def evaluate_trip(payload: TripEvaluationRequest):
    try:
        # Convert Pydantic items to dictionaries
        pts = [pt.dict() for pt in payload.points]
        evts = [evt.dict() for evt in payload.events]
        result = score_service.evaluate_trip(pts, evts)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate-crash-summary")
def generate_crash_summary(payload: CrashSummaryRequest):
    try:
        result = crash_service.generate_summary(payload.crash_report_id, payload.sensor_values)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
