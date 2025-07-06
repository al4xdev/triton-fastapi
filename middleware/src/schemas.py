from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ErrorLog(BaseModel):
    erro_id: int
    project_id: Optional[str]
    inference_log: Optional[str]
    middleware_log: Optional[str]
    timestamp: datetime

class UsageLog(BaseModel):
    project_id: Optional[str]
    tokens_usage: int
    last_update: datetime

class ErrorsResponse(BaseModel):
    errors: list[ErrorLog]

class UsageResponse(BaseModel):
    usage: list[UsageLog]