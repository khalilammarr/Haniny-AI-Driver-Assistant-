from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, DateTime, Float
from sqlalchemy.orm import relationship
from database import Base
import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String)
    car_model = Column(String)
    is_verified = Column(Boolean, default=False)
    verification_code = Column(String)
    device_id = Column(String, nullable=True, index=True)
    
    alerts = relationship("Alert", back_populates="owner")
    scores = relationship("ScoreHistory", back_populates="user")
    trips = relationship("Trip", back_populates="user")

class Trip(Base):
    __tablename__ = "trips"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    device_id = Column(String)
    start_time = Column(DateTime, default=datetime.datetime.utcnow)
    end_time = Column(DateTime, nullable=True)
    initial_score = Column(Integer, default=100)
    final_score = Column(Integer, nullable=True)
    distance = Column(Float, nullable=True)
    duration = Column(Integer, nullable=True)
    
    user = relationship("User", back_populates="trips")
    alerts = relationship("Alert", back_populates="trip")
    scores = relationship("ScoreHistory", back_populates="trip")

class Alert(Base):
    __tablename__ = "alerts"

    id = Column(Integer, primary_key=True, index=True)
    alert_type = Column(String, index=True)  # Changed from 'type' to 'alert_type'
    message = Column(String)
    severity = Column(String)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    user_id = Column(Integer, ForeignKey("users.id"))
    trip_id = Column(Integer, ForeignKey("trips.id"), nullable=True)

    owner = relationship("User", back_populates="alerts")
    trip = relationship("Trip", back_populates="alerts")

class ScoreHistory(Base):
    __tablename__ = "score_history"

    id = Column(Integer, primary_key=True, index=True)
    score = Column(Integer)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    user_id = Column(Integer, ForeignKey("users.id"))
    trip_id = Column(Integer, ForeignKey("trips.id"), nullable=True)

    user = relationship("User", back_populates="scores")
    trip = relationship("Trip", back_populates="scores")
