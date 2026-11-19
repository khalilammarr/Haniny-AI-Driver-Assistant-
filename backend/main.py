from fastapi import FastAPI, Depends, HTTPException, status, WebSocket, WebSocketDisconnect, Header
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from typing import List, Optional
import os
import secrets
import json
import base64
import cv2
import numpy as np
import asyncio
import time

import models, schemas, auth
from database import SessionLocal, engine, get_db

# Import detection modules
from detection_modules.fatigue_detection import FACE_MESH, is_driver_drowsy, reset_counters
from detection_modules.smoking_detection import SmokingDetection
from detection_modules.animal_detection import AnimalDetection
# from detection_modules.posture_detection import PostureDetection # Deprecated
from detection_modules.sign_detection import StopSignDetection
from detection_modules.driver_attention import check_driver_attention
from detection_modules.road_damage_detection import RoadDamageDetection

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# Initialize detection models
smoking_detector = SmokingDetection()
animal_detector = AnimalDetection()
# posture_detector = PostureDetection()
road_damage_detector = RoadDamageDetection()
stop_sign_detector = StopSignDetection(cascade_path="detection_modules/cascade_stop_sign.xml")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Dependency to get current user
async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = auth.jwt.decode(token, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = schemas.TokenData(email=email)
    except auth.JWTError:
        raise credentials_exception
    user = db.query(models.User).filter(models.User.email == token_data.email).first()
    if user is None:
        raise credentials_exception
    return user

# --- Health Check ---

@app.get("/health")
def health_check():
    """Simple health check endpoint to verify server is running"""
    return {"status": "ok", "message": "Server is running"}

# --- Auth Endpoints ---

import random
import string

def generate_verification_code():
    return ''.join(random.choices(string.digits, k=6))

@app.post("/register", response_model=schemas.User)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = auth.get_password_hash(user.password)
    verification_code = generate_verification_code()
    
    # In a real app, send this code via email.
    # For now, we log it to the console.
    print(f"📧 VERIFICATION CODE for {user.email}: {verification_code}")
    
    db_user = models.User(
        email=user.email, 
        hashed_password=hashed_password, 
        full_name=user.full_name,
        car_model=user.car_model,
        verification_code=verification_code,
        is_verified=False
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/verify")
def verify_email(email: str, code: str, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if user.verification_code != code:
        raise HTTPException(status_code=400, detail="Invalid verification code")
    
    user.is_verified = True
    user.verification_code = None # Clear code after success
    db.commit()
    
    return {"message": "Email verified successfully"}

@app.post("/token", response_model=schemas.Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = auth.timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me", response_model=schemas.User)
async def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user

@app.get("/stats")
def get_stats(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Get alerts
    alerts = current_user.alerts
    
    # Get score history
    scores = db.query(models.ScoreHistory).filter(models.ScoreHistory.user_id == current_user.id).order_by(models.ScoreHistory.timestamp).all()
    
    # Calculate average score
    average_score = 100
    if scores:
        total_score = sum(s.score for s in scores)
        average_score = int(total_score / len(scores))
    elif not scores:
        # If no history, default to 100
        average_score = 100
        
    return {
        "alerts": alerts,
        "scores": scores,
        "average_score": average_score
    }

# --- Admin Endpoints ---

def require_admin(x_admin_token: Optional[str] = Header(default=None)):
    """Admin routes need the X-Admin-Token header to match HANINY_ADMIN_TOKEN.
    Without that variable the admin routes are disabled."""
    expected = os.environ.get("HANINY_ADMIN_TOKEN")
    if not expected or not x_admin_token or not secrets.compare_digest(x_admin_token, expected):
        raise HTTPException(status_code=403, detail="Admin access denied")


@app.get("/admin/users", response_model=List[schemas.User], dependencies=[Depends(require_admin)])
def get_all_users(db: Session = Depends(get_db)):
    """
    Admin endpoint to list all registered users.
    Access via: http://YOUR_IP:8000/admin/users
    """
    users = db.query(models.User).all()
    return users

@app.get("/admin/alerts", dependencies=[Depends(require_admin)])
def get_all_alerts(db: Session = Depends(get_db)):
    """
    Admin endpoint to list all alerts from all users.
    Access via: http://YOUR_IP:8000/admin/alerts
    """
    alerts = db.query(models.Alert).all()
    return alerts

@app.post("/alerts/log")
def log_alert(
    trip_id: int,
    alert_type: str,
    severity: str = "medium",
    db: Session = Depends(get_db)
):
    """
    Log an alert for a specific trip.
    This is called from the hardware app when an alert is triggered.
    """
    import datetime
    
    # Verify trip exists
    trip = db.query(models.Trip).filter(models.Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    
    # Create alert
    new_alert = models.Alert(
        trip_id=trip_id,
        user_id=trip.user_id,
        alert_type=alert_type,
        severity=severity,
        timestamp=datetime.datetime.utcnow()
    )
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)
    
    return {
        "alert_id": new_alert.id,
        "trip_id": trip_id,
        "alert_type": alert_type,
        "severity": severity,
        "timestamp": new_alert.timestamp.isoformat()
    }

# --- Trip Management Endpoints ---

@app.post("/trips/start")
def start_trip(device_id: str, db: Session = Depends(get_db)):
    """
    Start a new trip for a device.
    Returns the trip_id to be used for subsequent alerts.
    """
    # Find user by device_id
    user = db.query(models.User).filter(models.User.device_id == device_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Device not paired to any user")
    
    # Create new trip
    new_trip = models.Trip(
        user_id=user.id,
        device_id=device_id,
        initial_score=100
    )
    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)
    
    return {
        "trip_id": new_trip.id,
        "user_id": user.id,
        "start_time": new_trip.start_time.isoformat(),
        "initial_score": new_trip.initial_score
    }

@app.put("/trips/{trip_id}/end")
def end_trip(trip_id: int, final_score: int = None, distance: float = None, db: Session = Depends(get_db)):
    """
    End a trip and record final metrics.
    """
    trip = db.query(models.Trip).filter(models.Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    
    if trip.end_time is not None:
        raise HTTPException(status_code=400, detail="Trip already ended")
    
    import datetime
    trip.end_time = datetime.datetime.utcnow()
    trip.final_score = final_score if final_score is not None else trip.initial_score
    trip.distance = distance
    
    # Calculate duration in seconds
    if trip.start_time:
        trip.duration = int((trip.end_time - trip.start_time).total_seconds())
    
    db.commit()
    db.refresh(trip)
    
    return {
        "trip_id": trip.id,
        "start_time": trip.start_time.isoformat(),
        "end_time": trip.end_time.isoformat(),
        "duration": trip.duration,
        "initial_score": trip.initial_score,
        "final_score": trip.final_score,
        "distance": trip.distance
    }

@app.get("/stats/daily")
def get_daily_stats(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Get statistics grouped by day for the last 7 days.
    """
    import datetime
    from sqlalchemy import func
    
    # Get trips from last 7 days
    seven_days_ago = datetime.datetime.utcnow() - datetime.timedelta(days=7)
    trips = db.query(models.Trip).filter(
        models.Trip.user_id == current_user.id,
        models.Trip.start_time >= seven_days_ago
    ).order_by(models.Trip.start_time).all()
    
    # Group by day
    daily_data = {}
    for trip in trips:
        day_key = trip.start_time.date().isoformat()
        if day_key not in daily_data:
            daily_data[day_key] = {
                "date": day_key,
                "trips": [],
                "total_alerts": 0,
                "average_score": 0,
                "scores": []
            }
        
        
        # Get alerts for this trip
        alerts = db.query(models.Alert).filter(models.Alert.trip_id == trip.id).all()
        alert_list = []
        for alert in alerts:
            alert_list.append({
                "type": alert.alert_type,
                "severity": alert.severity,
                "time": alert.timestamp.strftime("%H:%M:%S") if alert.timestamp else "N/A"
            })
        
        trip_info = {
            "trip_id": trip.id,
            "start_time": trip.start_time.isoformat(),
            "end_time": trip.end_time.isoformat() if trip.end_time else None,
            "duration": str(trip.duration) if trip.duration else "N/A",
            "score": trip.final_score if trip.final_score is not None else trip.initial_score,
            "alerts": alert_list
        }
        daily_data[day_key]["trips"].append(trip_info)
        
        # Count alerts for this trip
        daily_data[day_key]["total_alerts"] += len(alert_list)
        
        # Add score if trip ended
        if trip.final_score is not None:
            daily_data[day_key]["scores"].append(trip.final_score)
    
    # Calculate average scores
    for day_key in daily_data:
        scores = daily_data[day_key]["scores"]
        if scores:
            daily_data[day_key]["average_score"] = sum(scores) / len(scores)
    
    return {"view": "daily", "data": list(daily_data.values())}

@app.get("/stats/weekly")
def get_weekly_stats(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Get statistics grouped by week for the last 8 weeks.
    """
    import datetime
    from sqlalchemy import func
    
    # Get trips from last 8 weeks
    eight_weeks_ago = datetime.datetime.utcnow() - datetime.timedelta(weeks=8)
    trips = db.query(models.Trip).filter(
        models.Trip.user_id == current_user.id,
        models.Trip.start_time >= eight_weeks_ago
    ).order_by(models.Trip.start_time).all()
    
    # Group by week
    weekly_data = {}
    for trip in trips:
        # Get ISO week number
        week_key = trip.start_time.isocalendar()
        week_str = f"{week_key[0]}-W{week_key[1]:02d}"
        
        # Calculate week start date for better naming
        import calendar
        year, week_num = week_key[0], week_key[1]
        # Get first day of the week
        first_day = datetime.datetime.strptime(f'{year}-W{week_num}-1', '%Y-W%W-%w')
        last_day = first_day + datetime.timedelta(days=6)
        
        # Format: "Week of Nov 18-24"
        week_display = f"Week of {first_day.strftime('%b %d')}-{last_day.strftime('%d')}"
        
        if week_str not in weekly_data:
            weekly_data[week_str] = {
                "week": week_display,  # Use friendly name
                "trips": [],
                "total_alerts": 0,
                "average_score": 0,
                "scores": []
            }
        
        
        # Get alerts for this trip
        alerts = db.query(models.Alert).filter(models.Alert.trip_id == trip.id).all()
        alert_list = []
        for alert in alerts:
            alert_list.append({
                "type": alert.alert_type,
                "severity": alert.severity,
                "time": alert.timestamp.strftime("%H:%M:%S") if alert.timestamp else "N/A"
            })
        
        trip_info = {
            "trip_id": trip.id,
            "start_time": trip.start_time.isoformat(),
            "end_time": trip.end_time.isoformat() if trip.end_time else None,
            "duration": str(trip.duration) if trip.duration else "N/A",
            "score": trip.final_score if trip.final_score is not None else trip.initial_score,
            "alerts": alert_list
        }
        weekly_data[week_str]["trips"].append(trip_info)
        
        # Count alerts for this trip
        weekly_data[week_str]["total_alerts"] += len(alert_list)
        
        # Add score if trip ended
        if trip.final_score is not None:
            weekly_data[week_str]["scores"].append(trip.final_score)
    
    # Calculate average scores (Average of Daily Averages)
    for week_key in weekly_data:
        week_trips = weekly_data[week_key]["trips"]
        if not week_trips:
            continue
            
        # Group by day first
        daily_scores = {}
        for trip in week_trips:
            # Parse start time to get date
            trip_date = trip["start_time"].split("T")[0]
            if trip_date not in daily_scores:
                daily_scores[trip_date] = []
            
            # Use final score if available, else initial
            score = trip["score"]
            if score is not None:
                daily_scores[trip_date].append(score)
        
        # Calculate average for each day
        day_averages = []
        for day in daily_scores:
            scores = daily_scores[day]
            if scores:
                day_avg = sum(scores) / len(scores)
                day_averages.append(day_avg)
        
        # Weekly average is average of daily averages
        if day_averages:
            weekly_data[week_key]["average_score"] = int(sum(day_averages) / len(day_averages))
    
    return {"view": "weekly", "data": list(weekly_data.values())}

# --- WebSocket Endpoint ---

# --- WebSocket Endpoint ---

@app.post("/pair")
def pair_device(device_id: str, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Link a hardware device ID to the current user.
    """
    if not device_id or len(device_id) != 6 or not device_id.isdigit():
        raise HTTPException(status_code=400, detail="Invalid device ID format. Must be 6 digits.")
    
    # Check if device is already paired to another user
    existing_pairing = db.query(models.User).filter(models.User.device_id == device_id).first()
    if existing_pairing and existing_pairing.id != current_user.id:
        raise HTTPException(status_code=400, detail="This device is already paired to another user.")
    
    current_user.device_id = device_id
    db.commit()
    return {
        "message": "Device paired successfully", 
        "device_id": device_id,
        "user_name": current_user.full_name
    }

@app.post("/unpair")
def unpair_device(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Unlink the current user from their hardware device.
    """
    if not current_user.device_id:
        raise HTTPException(status_code=400, detail="No device paired.")
    
    current_user.device_id = None
    db.commit()
    return {"message": "Device unpaired successfully"}

# Add endpoint to get paired user info (for hardware app)
@app.get("/device/{device_id}/user")
def get_device_user(device_id: str, db: Session = Depends(get_db)):
    """
    Get the user associated with a device ID.
    """
    user = db.query(models.User).filter(models.User.device_id == device_id).first()
    if not user:
        return {"paired": False, "user_name": None}
    return {
        "paired": True, 
        "user_name": user.full_name,
        "car_model": user.car_model
    }

@app.post("/emergency/accident")
def report_accident(accident_data: dict, db: Session = Depends(get_db)):
    """
    Report an accident from the user app.
    """
    print(f"🚨 ACCIDENT REPORT RECEIVED: {accident_data}")
    
    # Save to database if needed
    # For now, just log it and return success
    
    return {"status": "received", "message": "Emergency services notified"}

# --- WebSocket Endpoint ---

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str = None, device_id: str = None, trip_id: int = None, db: Session = Depends(get_db)):
    await websocket.accept()
    
    # Authenticate user
    user = None
    if token:
        try:
            payload = auth.jwt.decode(token, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
            email: str = payload.get("sub")
            if email:
                user = db.query(models.User).filter(models.User.email == email).first()
        except Exception as e:
            print(f"⚠️ Auth failed: {e}")
    
    # If no token, try device_id
    if not user and device_id:
        user = db.query(models.User).filter(models.User.device_id == device_id).first()
        if user:
             print(f"✅ Client connected via Device ID: {device_id} -> {user.full_name}")

    if user:
        print(f"✅ Client connected: {user.full_name}")
    else:
        print(f"⚠️ Client connected (Unauthenticated)")

    # Initialize score
    current_score = 100
    if trip_id:
        # Get last score for this specific trip
        last_score = db.query(models.ScoreHistory).filter(
            models.ScoreHistory.trip_id == trip_id
        ).order_by(models.ScoreHistory.timestamp.desc()).first()
        if last_score:
            current_score = last_score.score
            
    # Reset counters for new connection
    reset_counters()
    smoking_detector.reset_counter()
    reset_counters()
    smoking_detector.reset_counter()
    stop_sign_detector.reset_counter()
    
    # Alert cooldown tracking
    last_alert_times = {}
    ALERT_COOLDOWN = 3.0 # seconds
    
    try:
        while True:
            message = await websocket.receive_text()
            try:
                data = json.loads(message)
                if 'camera' not in data or 'frame' not in data:
                    continue

                # Decode frame
                frame_bytes = base64.b64decode(data['frame'])
                np_arr = np.frombuffer(frame_bytes, np.uint8)
                frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
                
                if frame is None:
                    continue

                # === DRIVER CAMERA ===
                if data['camera'] == 'driver':
                    image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    face_outputs = FACE_MESH.process(image_rgb)
                    
                    smoking_result = smoking_detector.get_detection_json(frame)
                    
                    alert_triggered = False
                    score_deduction = 0
                    
                    if smoking_result['alert']:
                        alert = {
                            'camera': 'driver',
                            'message': 'Smoking',
                            'critical': True,
                            'severity': smoking_result['severity'],
                            'details': smoking_result
                        }
                        print(f"🚬 SMOKING DETECTED")
                        alert_triggered = True
                        score_deduction = 5
                    else:
                        # 2. Driver Attention & Posture (MediaPipe Holistic)
                        attention_result = check_driver_attention(frame)
                        
                        if attention_result['status'] == 'ok':
                            details = attention_result['details']
                            
                            # Distraction
                            if not details['looking_at_road']:
                                alert = {
                                    'camera': 'driver',
                                    'message': 'Distracted',
                                    'critical': True,
                                    'severity': 'critical',
                                    'details': {'message': 'Regardez la route !'}
                                }
                                print(f"👀 DISTRACTION DETECTED")
                                alert_triggered = True
                                score_deduction = 5
                            
                            # Bad Posture
                            elif not details['proper_posture']:
                                alert = {
                                    'camera': 'driver',
                                    'message': 'Bad Posture',
                                    'critical': False,
                                    'severity': 'warning',
                                    'details': {'message': 'Mauvaise posture'}
                                }
                                print(f"🪑 BAD POSTURE DETECTED")
                                alert_triggered = True
                                score_deduction = 2

                        # 3. Fatigue Detection
                        if not alert_triggered and face_outputs.multi_face_landmarks:
                            fatigue_alert = is_driver_drowsy(frame, face_outputs)
                            if fatigue_alert == "Drowsy":
                                alert = {
                                    'camera': 'driver',
                                    'message': 'Drowsy',
                                    'critical': True,
                                    'severity': 'critical',
                                    'details': {'message': 'Somnolence détectée'}
                                }
                                print(f"😴 DROWSINESS DETECTED")
                                alert_triggered = True
                                score_deduction = 5
                            elif fatigue_alert == "Yawning":
                                alert = {
                                    'camera': 'driver',
                                    'message': 'Yawning',
                                    'critical': False,
                                    'severity': 'warning',
                                    'details': {'message': 'Bâillement détecté'}
                                }
                                alert_triggered = True
                                score_deduction = 2
                        
                        if not alert_triggered:
                            alert = {'camera': 'driver', 'message': 'OK', 'critical': False}
                    
                    # Update Score and Save Alert
                    # Check cooldown
                    if alert_triggered:
                        current_time = time.time()
                        last_time = last_alert_times.get(alert['message'], 0)
                        if current_time - last_time < ALERT_COOLDOWN:
                            alert_triggered = False
                            print(f"⏳ Alert cooldown active for {alert['message']}")
                        else:
                            last_alert_times[alert['message']] = current_time

                    # Save alert to database if user is authenticated
                    if user and alert_triggered:
                        db_alert = models.Alert(
                            alert_type=alert['message'].lower(),
                            message=alert['message'],
                            severity=alert['severity'],
                            user_id=user.id,
                            trip_id=trip_id
                        )
                        db.add(db_alert)
                        
                        # Update Score
                        current_score = max(0, current_score - score_deduction)
                        db_score = models.ScoreHistory(
                            score=current_score,
                            user_id=user.id,
                            trip_id=trip_id
                        )
                        db.add(db_score)
                        db.commit()
                        
                        # Add score to alert response
                        alert['current_score'] = current_score
                    
                    await websocket.send_json(alert)

                # === ROAD CAMERA ===
                elif data['camera'] == 'road':
                    # Animal Detection
                    animal_detections = animal_detector.get_detections_json(frame)
                    animals = ['cat', 'dog', 'bird', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe']
                    animal_detections = [d for d in animal_detections if d['label'] in animals]
                    
                    # Stop Sign Detection
                    sign_result = stop_sign_detector.get_detection_json(frame)
                    sign_detections = sign_result['detections']
                    
                    # Road Damage Detection
                    damage_detections = road_damage_detector.get_damages(frame)
                    
                    all_detections = animal_detections + sign_detections + damage_detections
                    is_critical = len(animal_detections) > 0 or sign_result['alert']
                    
                    message = 'OK'
                    score_deduction = 0
                    
                    if sign_result['alert']:
                        message = 'Stop Sign Missed'
                        score_deduction = 10
                    elif len(animal_detections) > 0:
                        message = 'Animal on Road'
                        score_deduction = 2
                    elif len(damage_detections) > 0:
                        message = 'Pothole Detected'
                        score_deduction = 2
                    
                    alert = {
                        'camera': 'road',
                        'message': message,
                        'critical': is_critical,
                        'detections': all_detections
                    }
                    
                    if is_critical:
                        print(f"🛣️ ROAD ALERT: {message}")
                        if user:
                            # Save Alert
                            db_alert = models.Alert(
                                alert_type="road_hazard",
                                message=message,
                                severity="critical" if sign_result['alert'] else "warning",
                                user_id=user.id,
                                trip_id=trip_id
                            )
                            db.add(db_alert)
                            
                            # Update Score
                            current_score = max(0, current_score - score_deduction)
                            db_score = models.ScoreHistory(
                                score=current_score,
                                user_id=user.id,
                                trip_id=trip_id
                            )
                            db.add(db_score)
                            db.commit()
                            
                            alert['current_score'] = current_score
                    
                    await websocket.send_json(alert)

            except json.JSONDecodeError:
                print("❌ Invalid JSON")
            except Exception as e:
                print(f"❌ Error processing frame: {e}")
                
    except WebSocketDisconnect:
        print("⚠️ Client disconnected")
