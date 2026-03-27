"""
Seed demo data for presentation
Creates a demo user with 7+ days of trip history, alerts, and realistic data
"""
import sys
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
import auth

def seed_demo_data():
    db = SessionLocal()
    
    try:
        # Create demo user
        demo_email = "demo@haniny.com"
        
        # Check if user exists
        existing_user = db.query(models.User).filter(models.User.email == demo_email).first()
        if existing_user:
            print(f"⚠️  Demo user already exists. Deleting old data...")
            # Delete old trips, alerts, scores
            db.query(models.ScoreHistory).filter(models.ScoreHistory.user_id == existing_user.id).delete()
            db.query(models.Alert).filter(models.Alert.user_id == existing_user.id).delete()
            db.query(models.Trip).filter(models.Trip.user_id == existing_user.id).delete()
            db.delete(existing_user)
            db.commit()
        
        # Create new demo user
        hashed_password = auth.get_password_hash("demo123")
        demo_user = models.User(
            email=demo_email,
            hashed_password=hashed_password,
            full_name="Ahmed Benali",
            car_model="Tesla Model 3",
            is_verified=True,
            verification_code=None,
            device_id="123456"
        )
        db.add(demo_user)
        db.commit()
        db.refresh(demo_user)
        
        print(f"✅ Created demo user: {demo_email} / demo123")
        print(f"   Full Name: {demo_user.full_name}")
        print(f"   Car: {demo_user.car_model}")
        print(f"   Device ID: {demo_user.device_id}")
        
        # Generate 10 days of trip history with diverse scenarios
        base_date = datetime.utcnow() - timedelta(days=9)
        
        trip_scenarios = [
            # Day 1 - Morning commute with minor issues
            {"trips": 2, "avg_score": 92, "alerts": ["Yawning Detected", "Lane Departure"]},
            # Day 2 - Good day with environmental awareness
            {"trips": 3, "avg_score": 88, "alerts": ["Yawning Detected", "Animal on Road", "High CO2 Emissions"]},
            # Day 3 - Challenging day with multiple safety issues
            {"trips": 2, "avg_score": 75, "alerts": ["Drowsiness Alert", "Stop Sign Missed", "Harsh Braking", "Phone Distraction"]},
            # Day 4 - Perfect driving day
            {"trips": 1, "avg_score": 100, "alerts": []},
            # Day 5 - Good with minor distractions
            {"trips": 3, "avg_score": 85, "alerts": ["Yawning Detected", "Pedestrian Alert", "Speed Limit Exceeded"]},
            # Day 6 - Moderate with fatigue signs
            {"trips": 2, "avg_score": 82, "alerts": ["Drowsiness Alert", "Yawning Detected", "Tailgating Warning"]},
            # Day 7 - Excellent recovery
            {"trips": 2, "avg_score": 95, "alerts": ["Lane Departure"]},
            # Day 8 - Good with road hazards
            {"trips": 3, "avg_score": 87, "alerts": ["Animal on Road", "Stop Sign Missed", "Pothole Detected"]},
            # Day 9 - Very good performance
            {"trips": 2, "avg_score": 93, "alerts": ["Yawning Detected", "High CO2 Emissions"]},
            # Day 10 (today) - Near perfect
            {"trips": 1, "avg_score": 98, "alerts": []},
        ]
        
        alert_types = {
            # Fatigue & Attention Alerts
            "Drowsiness Alert": {"severity": "critical", "score_deduction": 12},
            "Yawning Detected": {"severity": "warning", "score_deduction": 3},
            "Eyes Closed": {"severity": "critical", "score_deduction": 15},
            "Head Nodding": {"severity": "critical", "score_deduction": 10},
            
            # Distraction Alerts
            "Phone Distraction": {"severity": "critical", "score_deduction": 10},
            "Looking Away": {"severity": "warning", "score_deduction": 5},
            "Smoking Detected": {"severity": "critical", "score_deduction": 15},
            "Eating While Driving": {"severity": "warning", "score_deduction": 6},
            
            # Road Safety Alerts
            "Animal on Road": {"severity": "warning", "score_deduction": 2},
            "Pedestrian Alert": {"severity": "critical", "score_deduction": 8},
            "Cyclist Detected": {"severity": "warning", "score_deduction": 3},
            "Obstacle Ahead": {"severity": "critical", "score_deduction": 7},
            "Pothole Detected": {"severity": "warning", "score_deduction": 2},
            
            # Traffic Violations
            "Stop Sign Missed": {"severity": "critical", "score_deduction": 10},
            "Red Light Violation": {"severity": "critical", "score_deduction": 15},
            "Speed Limit Exceeded": {"severity": "warning", "score_deduction": 8},
            "Wrong Lane": {"severity": "warning", "score_deduction": 5},
            
            # Driving Behavior
            "Harsh Braking": {"severity": "warning", "score_deduction": 4},
            "Harsh Acceleration": {"severity": "warning", "score_deduction": 4},
            "Sharp Turn": {"severity": "warning", "score_deduction": 3},
            "Tailgating Warning": {"severity": "warning", "score_deduction": 6},
            "Lane Departure": {"severity": "warning", "score_deduction": 5},
            
            # Environmental
            "High CO2 Emissions": {"severity": "warning", "score_deduction": 3},
            "Excessive Idling": {"severity": "warning", "score_deduction": 2},
        }
        
        total_trips = 0
        
        for day_offset, scenario in enumerate(trip_scenarios):
            day_date = base_date + timedelta(days=day_offset)
            
            for trip_num in range(scenario["trips"]):
                # Create trip with realistic times
                start_hour = 8 if trip_num == 0 else (14 if trip_num == 1 else 18)
                start_time = day_date.replace(hour=start_hour, minute=0, second=0)
                duration_minutes = 25 + (trip_num * 10)
                end_time = start_time + timedelta(minutes=duration_minutes)
                
                # Distribute alerts across trips for this day
                total_alerts = len(scenario["alerts"])
                if total_alerts > 0 and scenario["trips"] > 0:
                    # Distribute alerts evenly, with remainder going to first trips
                    alerts_per_trip = total_alerts // scenario["trips"]
                    extra_alerts = total_alerts % scenario["trips"]
                    
                    start_idx = trip_num * alerts_per_trip + min(trip_num, extra_alerts)
                    end_idx = start_idx + alerts_per_trip + (1 if trip_num < extra_alerts else 0)
                    alerts_for_trip = scenario["alerts"][start_idx:end_idx]
                else:
                    alerts_for_trip = []
                
                # Calculate score based on alerts
                initial_score = 100
                final_score = initial_score
                for alert_type in alerts_for_trip:
                    if alert_type in alert_types:
                        final_score -= alert_types[alert_type]["score_deduction"]
                
                # Adjust to match avg_score with some variation
                final_score = max(60, min(100, scenario["avg_score"] + (trip_num - 1) * 3))
                
                # Create trip
                trip = models.Trip(
                    user_id=demo_user.id,
                    device_id=demo_user.device_id,
                    start_time=start_time,
                    end_time=end_time,
                    initial_score=initial_score,
                    final_score=final_score,
                    distance=round(5.5 + trip_num * 2.3, 2),
                    duration=duration_minutes * 60
                )
                db.add(trip)
                db.commit()
                db.refresh(trip)
                
                total_trips += 1
                
                # Add alerts for this trip
                for i, alert_type in enumerate(alerts_for_trip):
                    if alert_type in alert_types:
                        alert_time = start_time + timedelta(minutes=5 + i * 7)
                        alert = models.Alert(
                            user_id=demo_user.id,
                            trip_id=trip.id,
                            alert_type=alert_type,
                            message=alert_type,  # Keep the full name
                            severity=alert_types[alert_type]["severity"],
                            timestamp=alert_time
                        )
                        db.add(alert)
                
                # Add score history entries
                score_time = start_time + timedelta(minutes=10)
                score_entry = models.ScoreHistory(
                    user_id=demo_user.id,
                    trip_id=trip.id,
                    score=final_score,
                    timestamp=score_time
                )
                db.add(score_entry)
        
        db.commit()
        
        print(f"\n✅ Created {total_trips} trips with realistic data")
        print(f"✅ Added alerts and score history")
        print(f"\n📊 Demo Account Credentials:")
        print(f"   Email: demo@haniny.com")
        print(f"   Password: demo123")
        print(f"   Device ID: 123456")
        print(f"\n🎬 Ready for demo presentation!")
        
    except Exception as e:
        print(f"❌ Error seeding data: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    print("🌱 Seeding demo data...")
    seed_demo_data()
