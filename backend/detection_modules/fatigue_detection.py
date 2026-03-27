import mediapipe as mp
from scipy.spatial import distance as dis

# --- MediaPipe Face Mesh setup ---
mp_face_mesh = mp.solutions.face_mesh
FACE_MESH = mp_face_mesh.FaceMesh(
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.6,
    min_tracking_confidence=0.5
)

# --- Landmark indices (from original code) ---
LEFT_EYE_TOP_BOTTOM = [386, 374]
LEFT_EYE_LEFT_RIGHT = [263, 362]
RIGHT_EYE_TOP_BOTTOM = [159, 145]
RIGHT_EYE_LEFT_RIGHT = [133, 33]
UPPER_LOWER_LIPS = [13, 14]
LEFT_RIGHT_LIPS = [78, 308]

# --- Thresholds (from original code) ---
EYE_CLOSURE_THRESHOLD = 5.0  # Eyes closing when ratio > 5.0
YAWNING_THRESHOLD = 1.8      # Mouth opening when ratio < 1.8
FRAME_COUNT_LIMIT = 6        # Number of consecutive frames to trigger alert

# --- Frame counters ---
frame_count_dict = {'eye': 0, 'yawn': 0}


def euclidean_distance(image, top, bottom):
    """Calculate Euclidean distance between two facial landmarks."""
    height, width = image.shape[0:2]
    
    point1 = int(top.x * width), int(top.y * height)
    point2 = int(bottom.x * width), int(bottom.y * height)
    
    distance = dis.euclidean(point1, point2)
    return distance


def get_aspect_ratio(image, outputs, top_bottom, left_right):
    """
    Calculate aspect ratio for eye or mouth.
    Returns the ratio of horizontal distance to vertical distance.
    This matches the original code's logic exactly.
    """
    landmark = outputs.multi_face_landmarks[0]
    
    top = landmark.landmark[top_bottom[0]]
    bottom = landmark.landmark[top_bottom[1]]
    top_bottom_dis = euclidean_distance(image, top, bottom)
    
    left = landmark.landmark[left_right[0]]
    right = landmark.landmark[left_right[1]]
    left_right_dis = euclidean_distance(image, left, right)
    
    aspect_ratio = left_right_dis / top_bottom_dis
    
    return aspect_ratio


def reset_counters():
    """Reset frame counters for a new monitoring session."""
    frame_count_dict['eye'] = 0
    frame_count_dict['yawn'] = 0
    print("🔄 Frame counters reset")


def is_driver_drowsy(image, outputs):
    """
    Detect drowsiness or yawning using the original detection logic.
    
    Args:
        image: The frame image (numpy array)
        outputs: MediaPipe face mesh detection results
    
    Returns:
        - "Drowsy" if eyes are closed for FRAME_COUNT_LIMIT frames
        - "Yawning" if mouth is open for FRAME_COUNT_LIMIT frames
        - None otherwise
    """
    if outputs is None or not outputs.multi_face_landmarks:
        return None

    # --- Compute aspect ratios (original method) ---
    ratio_left = get_aspect_ratio(image, outputs, LEFT_EYE_TOP_BOTTOM, LEFT_EYE_LEFT_RIGHT)
    ratio_right = get_aspect_ratio(image, outputs, RIGHT_EYE_TOP_BOTTOM, RIGHT_EYE_LEFT_RIGHT)
    ear = (ratio_left + ratio_right) / 2.0
    
    mar = get_aspect_ratio(image, outputs, UPPER_LOWER_LIPS, LEFT_RIGHT_LIPS)

    # --- Detection logic (following original code exactly) ---
    alert_msg = None

    # Eye closure detection: ratio > threshold means eyes are closing
    if ear > EYE_CLOSURE_THRESHOLD:
        frame_count_dict['eye'] += 1
    else:
        frame_count_dict['eye'] = 0

    # Yawning detection: ratio < threshold means mouth is opening
    if mar < YAWNING_THRESHOLD:
        frame_count_dict['yawn'] += 1
    else:
        frame_count_dict['yawn'] = 0

    # Generate alerts if sustained (using > not >= to match original)
    if frame_count_dict['eye'] > FRAME_COUNT_LIMIT:
        alert_msg = "Drowsy"
    elif frame_count_dict['yawn'] > FRAME_COUNT_LIMIT:
        alert_msg = "Yawning"

    return alert_msg