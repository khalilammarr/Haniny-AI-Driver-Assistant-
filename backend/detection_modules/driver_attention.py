import mediapipe as mp

mp_drawing = mp.solutions.drawing_utils
mp_holistic = mp.solutions.holistic

HOLISTIC = mp_holistic.Holistic(
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

def is_driver_looking_at_road(face_landmarks):
    """Check if driver is looking at the road (frontal face)."""
    # Nose tip: 1, Left eye outer: 33, Right eye outer: 263
    nose = face_landmarks.landmark[1]
    left_eye = face_landmarks.landmark[33]
    right_eye = face_landmarks.landmark[263]
    
    # 1. Check Head Yaw (Turning left/right)
    # Distance from nose to left eye vs right eye
    dist_left = abs(nose.x - left_eye.x)
    dist_right = abs(nose.x - right_eye.x)
    
    if dist_right == 0: dist_right = 0.001
    ratio = dist_left / dist_right
    
    # If ratio is extreme, head is turned
    if ratio < 0.2 or ratio > 5.0:
        return False
        
    # 2. Check Head Roll (Tilting)
    eye_y_diff = abs(left_eye.y - right_eye.y)
    if eye_y_diff > 0.2:
        return False
        
    return True

def is_driver_holding_steering_wheel(left_hand_landmarks, right_hand_landmarks):
    """Check if driver is properly holding steering wheel."""
    if left_hand_landmarks and right_hand_landmarks:
        left_hand_y = left_hand_landmarks.landmark[0].y
        right_hand_y = right_hand_landmarks.landmark[0].y
        steering_wheel_height_threshold = 0.05

        if abs(left_hand_y - right_hand_y) <= steering_wheel_height_threshold:
            return True
    return False

def is_driver_maintaining_posture(pose_landmarks):
    """Check if driver is maintaining proper posture."""
    left_shoulder = pose_landmarks.landmark[mp_holistic.PoseLandmark.LEFT_SHOULDER.value]
    right_shoulder = pose_landmarks.landmark[mp_holistic.PoseLandmark.RIGHT_SHOULDER.value]
    left_hip = pose_landmarks.landmark[mp_holistic.PoseLandmark.LEFT_HIP.value]
    right_hip = pose_landmarks.landmark[mp_holistic.PoseLandmark.RIGHT_HIP.value]

    shoulder_line = abs(left_shoulder.y - right_shoulder.y)
    hip_line = abs(left_hip.y - right_hip.y)

    threshold = 0.05

    if shoulder_line <= threshold and hip_line <= threshold:
        return True
    return False

def process_frame_holistic(frame):
    """
    Process frame with holistic detection.
    Returns: results object or None
    """
    import cv2
    try:
        image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = HOLISTIC.process(image_rgb)
        return results
    except Exception as e:
        print(f"❌ Error in holistic processing: {e}")
        return None

def check_driver_attention(frame):
    """
    Comprehensive driver attention check.
    Returns: dict with attention status
    """
    results = process_frame_holistic(frame)
    
    if results is None:
        return {"status": "error", "details": {}}
    
    attention_status = {
        "looking_at_road": False,
        "holding_steering_wheel": False,
        "proper_posture": False
    }

    if results.face_landmarks:
        attention_status["looking_at_road"] = is_driver_looking_at_road(results.face_landmarks)
    
    if results.left_hand_landmarks and results.right_hand_landmarks:
        attention_status["holding_steering_wheel"] = is_driver_holding_steering_wheel(
            results.left_hand_landmarks, 
            results.right_hand_landmarks
        )
    
    if results.pose_landmarks:
        attention_status["proper_posture"] = is_driver_maintaining_posture(results.pose_landmarks)

    return {"status": "ok", "details": attention_status}
