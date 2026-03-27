import cv2
import mediapipe as mp
import numpy as np
from scipy.spatial import distance as dis

class SmokingDetection:
    def __init__(self):
        """Initialize MediaPipe Face Mesh and Hands for smoking detection."""
        # MediaPipe setup
        mp_face_mesh = mp.solutions.face_mesh
        mp_hands = mp.solutions.hands
        
        self.face_mesh = mp_face_mesh.FaceMesh(
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.6,
            min_tracking_confidence=0.5
        )
        
        self.hands = mp_hands.Hands(
            max_num_hands=2,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
        # Mouth landmarks for center calculation
        self.mouth_landmarks = [61, 291, 0, 17, 84, 314]
        
        # Detection thresholds
        self.hand_to_mouth_distance_threshold = 50  # pixels
        self.sustained_frames_threshold = 10        # consecutive frames
        
        # Frame counter
        self.frame_count = 0
        
        print("🚬 Smoking Detection initialized")
    
    def get_mouth_center(self, face_landmarks, image_shape):
        """Calculate the center position of the mouth."""
        height, width = image_shape[0:2]
        
        mouth_points = []
        for idx in self.mouth_landmarks:
            landmark = face_landmarks.landmark[idx]
            x = int(landmark.x * width)
            y = int(landmark.y * height)
            mouth_points.append((x, y))
        
        # Calculate average center
        center_x = int(np.mean([p[0] for p in mouth_points]))
        center_y = int(np.mean([p[1] for p in mouth_points]))
        
        return (center_x, center_y)
    
    def get_hand_tip_position(self, hand_landmarks, image_shape):
        """
        Get the position of fingertips (index and middle).
        Typically used for holding a cigarette.
        """
        height, width = image_shape[0:2]
        
        # Index fingertip (landmark 8) and Middle fingertip (landmark 12)
        index_tip = hand_landmarks.landmark[8]
        middle_tip = hand_landmarks.landmark[12]
        
        index_x = int(index_tip.x * width)
        index_y = int(index_tip.y * height)
        middle_x = int(middle_tip.x * width)
        middle_y = int(middle_tip.y * height)
        
        # Average position between index and middle (where cigarette would be)
        hand_x = (index_x + middle_x) // 2
        hand_y = (index_y + middle_y) // 2
        
        return (hand_x, hand_y)
    
    def detect_smoking_gesture(self, frame):
        """
        Detect if the driver is making a smoking gesture.
        
        Criteria:
        1. Hand detected near mouth
        2. Sustained gesture for several frames
        3. Characteristic position (fingers near mouth)
        
        Args:
            frame: Input image (numpy array)
        
        Returns:
            dict: {
                'smoking_detected': bool,
                'confidence': float,
                'frames_count': int,
                'distance': float or None
            }
        """
        # Convert to RGB for MediaPipe
        image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Process frame
        face_outputs = self.face_mesh.process(image_rgb)
        hand_outputs = self.hands.process(image_rgb)
        
        result = {
            'smoking_detected': False,
            'confidence': 0.0,
            'frames_count': self.frame_count,
            'distance': None
        }
        
        # Check if face is detected
        if not face_outputs.multi_face_landmarks:
            self.frame_count = 0
            return result
        
        # Check if hands are detected
        if not hand_outputs.multi_hand_landmarks:
            self.frame_count = 0
            return result
        
        # Get mouth center
        face_landmarks = face_outputs.multi_face_landmarks[0]
        mouth_center = self.get_mouth_center(face_landmarks, frame.shape)
        
        # Check each detected hand
        min_distance = float('inf')
        smoking_detected = False
        
        for hand_landmarks in hand_outputs.multi_hand_landmarks:
            hand_position = self.get_hand_tip_position(hand_landmarks, frame.shape)
            
            # Calculate distance between hand and mouth
            distance = dis.euclidean(mouth_center, hand_position)
            min_distance = min(min_distance, distance)
            
            # If hand is near mouth
            if distance < self.hand_to_mouth_distance_threshold:
                smoking_detected = True
                break
        
        # Update frame counter
        if smoking_detected:
            self.frame_count += 1
        else:
            self.frame_count = 0
        
        # Determine if alert should be triggered
        alert_triggered = self.frame_count > self.sustained_frames_threshold
        
        # Calculate confidence based on sustained frames
        confidence = min(1.0, self.frame_count / self.sustained_frames_threshold)
        
        result = {
            'smoking_detected': alert_triggered,
            'confidence': confidence,
            'frames_count': self.frame_count,
            'distance': min_distance if min_distance != float('inf') else None
        }
        
        return result
    
    def get_detection_json(self, frame):
        """
        Get smoking detection result in JSON-ready format.
        
        Args:
            frame: Input image (numpy array)
        
        Returns:
            dict: Detection result with alert information
        """
        detection = self.detect_smoking_gesture(frame)
        
        if detection['smoking_detected']:
            return {
                'alert': True,
                'message': 'Cigarette détectée! Interdit de fumer en conduisant',
                'severity': 'critical',
                'confidence': detection['confidence'],
                'frames_count': detection['frames_count'],
                'distance': detection['distance']
            }
        else:
            return {
                'alert': False,
                'message': 'OK',
                'severity': 'normal',
                'confidence': detection['confidence'],
                'frames_count': detection['frames_count'],
                'distance': detection['distance']
            }
    
    def reset_counter(self):
        """Reset the frame counter."""
        self.frame_count = 0
        print("🔄 Smoking detection counter reset")
    
    def set_thresholds(self, distance_threshold=None, frames_threshold=None):
        """
        Adjust detection thresholds.
        
        Args:
            distance_threshold: Maximum distance between hand and mouth (pixels)
            frames_threshold: Number of consecutive frames to trigger alert
        """
        if distance_threshold is not None:
            self.hand_to_mouth_distance_threshold = distance_threshold
            print(f"✅ Distance threshold set to {distance_threshold} pixels")
        
        if frames_threshold is not None:
            self.sustained_frames_threshold = frames_threshold
            print(f"✅ Frames threshold set to {frames_threshold} frames")


# Example usage
if __name__ == "__main__":
    # Test with webcam
    detector = SmokingDetection()
    cap = cv2.VideoCapture(0)
    
    print("🎥 Starting smoking detection test...")
    print("Press 'q' to quit, 'r' to reset counter")
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        
        # Detect smoking
        result = detector.get_detection_json(frame)
        
        # Display result
        if result['alert']:
            text = f"SMOKING DETECTED! ({result['frames_count']} frames)"
            color = (0, 0, 255)  # Red
        else:
            text = f"Monitoring... (confidence: {result['confidence']:.2f})"
            color = (0, 255, 0)  # Green
        
        cv2.putText(frame, text, (10, 30), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        
        if result['distance'] is not None:
            distance_text = f"Distance: {result['distance']:.1f}px"
            cv2.putText(frame, distance_text, (10, 60), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        cv2.imshow('Smoking Detection Test', frame)
        
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('r'):
            detector.reset_counter()
    
    cap.release()
    cv2.destroyAllWindows()