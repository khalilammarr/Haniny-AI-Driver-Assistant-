import asyncio
import websockets
import json
import base64
import cv2
import numpy as np

# Import detection modules
from detection_modules.fatigue_detection import (
    FACE_MESH,
    is_driver_drowsy,
    reset_counters
)
from detection_modules.smoking_detection import SmokingDetection
from detection_modules.animal_detection import AnimalDetection
from detection_modules.sign_detection import StopSignDetection
from detection_modules.driver_attention import check_driver_attention
from detection_modules.road_damage_detection import RoadDamageDetection

# Initialize detection models
smoking_detector = SmokingDetection()
animal_detector = AnimalDetection()
# posture_detector = PostureDetection() # Replaced by MediaPipe in driver_attention
road_damage_detector = RoadDamageDetection()
stop_sign_detector = StopSignDetection(cascade_path="detection_modules/cascade_stop_sign.xml")

# Track connections
active_connections = {}

async def handler(websocket):
    path = websocket.path
    client_id = id(websocket)
    print(f"✅ Client {client_id} connected on path: {path}")

    if path != "/ws":
        print(f"❌ Rejected connection on unexpected path: {path}")
        await websocket.close()
        return

    # Reset counters for new connection
    reset_counters()
    smoking_detector.reset_counter()
    stop_sign_detector.reset_counter()
    active_connections[client_id] = websocket
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                if 'camera' not in data or 'frame' not in data:
                    print("⚠️ Invalid message format")
                    continue

                # Decode frame
                frame_bytes = base64.b64decode(data['frame'])
                np_arr = np.frombuffer(frame_bytes, np.uint8)
                frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
                
                if frame is None:
                    print("❌ Failed to decode frame")
                    continue

                # print(f"📸 Received frame from {data['camera']}: {frame.shape}")

                # === DRIVER CAMERA: Fatigue + Smoking + Attention + Posture ===
                if data['camera'] == 'driver':
                    # 1. Smoking Detection (Highest Priority)
                    smoking_result = smoking_detector.get_detection_json(frame)
                    
                    if smoking_result['alert']:
                        alert = {
                            'camera': 'driver',
                            'message': 'Smoking',
                            'critical': True,
                            'severity': smoking_result['severity'],
                            'details': smoking_result
                        }
                        print(f"🚬 ALERTE CIGARETTE")
                        await websocket.send(json.dumps(alert))
                        continue # Skip other checks if smoking

                    # 2. Driver Attention & Posture (MediaPipe Holistic)
                    # This checks: Looking at road, Hands on wheel, Posture
                    attention_result = check_driver_attention(frame)
                    
                    if attention_result['status'] == 'ok':
                        details = attention_result['details']
                        
                        # Distraction (Not looking at road)
                        if not details['looking_at_road']:
                            alert = {
                                'camera': 'driver',
                                'message': 'Distracted',
                                'critical': True,
                                'severity': 'critical',
                                'details': {'message': 'Regardez la route !'}
                            }
                            print(f"👀 ALERTE DISTRACTION (Regard)")
                            await websocket.send(json.dumps(alert))
                        
                        # Bad Posture
                        elif not details['proper_posture']:
                            alert = {
                                'camera': 'driver',
                                'message': 'Bad Posture',
                                'critical': False,
                                'severity': 'warning',
                                'details': {'message': 'Mauvaise posture détectée'}
                            }
                            print(f"🪑 ALERTE POSTURE")
                            await websocket.send(json.dumps(alert))

                    # 3. Fatigue Detection (Drowsiness/Yawning)
                    # Convert to RGB for MediaPipe Face Mesh
                    image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    face_outputs = FACE_MESH.process(image_rgb)
                    
                    if face_outputs.multi_face_landmarks:
                        fatigue_alert = is_driver_drowsy(frame, face_outputs)
                        
                        if fatigue_alert == "Drowsy":
                            alert = {
                                'camera': 'driver',
                                'message': 'Drowsy',
                                'critical': True,
                                'severity': 'critical',
                                'details': {'message': 'Somnolence détectée'}
                            }
                            print(f"😴 ALERTE SOMNOLENCE")
                            await websocket.send(json.dumps(alert))
                        elif fatigue_alert == "Yawning":
                            alert = {
                                'camera': 'driver',
                                'message': 'Yawning',
                                'critical': False,
                                'severity': 'warning',
                                'details': {'message': 'Bâillement détecté'}
                            }
                            print(f"🥱 ALERTE BÂILLEMENT")
                            await websocket.send(json.dumps(alert))

                # === ROAD CAMERA: Animal + Sign + Road Damage ===
                elif data['camera'] == 'road':
                    # 1. Animal Detection
                    animal_detections = animal_detector.get_detections_json(frame)
                    animals = ['cat', 'dog', 'horse', 'sheep', 'cow', 'bear']
                    animal_detections = [d for d in animal_detections if d['label'] in animals]
                    
                    # 2. Stop Sign Detection
                    sign_result = stop_sign_detector.get_detection_json(frame)
                    
                    # 3. Road Damage Detection
                    damage_detections = road_damage_detector.get_damages(frame)
                    
                    # Combine alerts
                    is_critical = False
                    message = 'OK'
                    
                    if sign_result['alert']:
                        message = 'Stop Sign Missed' # Changed text to match frontend expectations often
                        is_critical = True
                    elif len(animal_detections) > 0:
                        message = 'Animal on Road'
                        is_critical = False # Warning usually
                    elif len(damage_detections) > 0:
                        message = 'Pothole Detected'
                        is_critical = False
                    
                    if message != 'OK':
                        alert = {
                            'camera': 'road',
                            'message': message,
                            'critical': is_critical,
                            'detections': {
                                'animals': animal_detections,
                                'signs': sign_result['detections'],
                                'damage': damage_detections
                            }
                        }
                        print(f"🛣️ ROAD ALERT: {message}")
                        await websocket.send(json.dumps(alert))
                
            except json.JSONDecodeError:
                print("❌ Invalid JSON received")
            except Exception as e:
                print(f"❌ Error during processing: {e}")
                # import traceback
                # traceback.print_exc()
    
    except websockets.exceptions.ConnectionClosed:
        print(f"⚠️ Client {client_id} disconnected")
    finally:
        if client_id in active_connections:
            del active_connections[client_id]
        print(f"🧹 Cleaned up client {client_id}")

async def main():
    print("🚀 Backend starting on ws://0.0.0.0:8765/ws")
    print("📋 Detection features:")
    print("   - 😴 Drowsiness & Yawning (Face Mesh)")
    print("   - 🚬 Smoking detection (YOLO)")
    print("   - 👀 Distraction & Posture (Holistic)")
    print("   - 🛑 Stop Signs (Cascade)")
    print("   - 🐾 Animals & 🕳️ Road Damage (YOLO)")
    
    async with websockets.serve(handler, "0.0.0.0", 8765):
        print("✅ Server ready and listening...")
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())