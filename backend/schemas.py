from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class AlertBase(BaseModel):
    type: str
    message: str
    severity: str

class AlertCreate(AlertBase):
    pass

class Alert(AlertBase):
    id: int
    timestamp: datetime
    user_id: int

    class Config:
        from_attributes = True

class ScoreHistoryBase(BaseModel):
    score: int
    timestamp: datetime

class ScoreHistory(ScoreHistoryBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True

class UserBase(BaseModel):
    email: str
    full_name: Optional[str] = None
    car_model: Optional[str] = None
    device_id: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class User(UserBase):
    id: int
    alerts: List[Alert] = []
    scores: List[ScoreHistory] = []

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None
