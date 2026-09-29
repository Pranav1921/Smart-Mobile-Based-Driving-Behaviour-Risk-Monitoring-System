import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "SmartDrive AI Engine"
    
    # AI Rules Thresholds
    OVERSPEED_THRESHOLD_KPH: float = 80.0
    HARSH_BRAKING_THRESHOLD_G: float = -3.0
    RAPID_ACCELERATION_THRESHOLD_G: float = 3.0
    SHARP_TURN_THRESHOLD_RAD: float = 4.0
    
    class Config:
        case_sensitive = True

settings = Settings()
