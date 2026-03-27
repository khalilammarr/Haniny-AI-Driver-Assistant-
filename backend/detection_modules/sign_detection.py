import cv2
import os
import time

class StopSignDetection:
    def __init__(self, cascade_path="cascade_stop_sign.xml"):
        """Initialize stop sign detection."""
        print(f"📦 Loading cascade classifier from: {cascade_path}")
        
        if os.path.exists(cascade_path):
            self.cascade = cv2.CascadeClassifier(cascade_path)
            if self.cascade.empty():
                print(f"⚠️ Failed to load cascade classifier")
                self.cascade = None
            else:
                print(f"✅ Stop sign cascade loaded successfully")
        else:
            print(f"⚠️ Cascade file not found at {cascade_path}")
            self.cascade = None
        
        self.scale_factor = 1.05  # Finer scale steps for better accuracy
        self.min_neighbors = 4    # Reduced for faster detection
        self.min_size = (40, 40)  # Slightly larger minimum size
        self.max_size = (400, 400) # Added max size to skip false positives
        
        self.consecutive_detections = 0
        self.detection_threshold = 3  # Number of consecutive frames needed
        self.alert_active = False
        self.last_detection_time = 0
        self.frame_skip = 0  # Frame counter for optional skipping
        self.process_every_n_frames = 1  # Process every frame (set to 2-3 for speed)
    
    def detect_stop_signs(self, frame):
        """Detect stop signs in frame with optimized processing."""
        if self.cascade is None:
            return []
        
        try:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            gray = cv2.equalizeHist(gray)
            
            height, width = gray.shape
            if width > 640:  # Only resize if large
                scale = 640 / width
                gray = cv2.resize(gray, (int(width * scale), int(height * scale)))
            
            stop_signs = self.cascade.detectMultiScale(
                gray,
                scaleFactor=self.scale_factor,
                minNeighbors=self.min_neighbors,
                minSize=self.min_size,
                maxSize=self.max_size,
                flags=cv2.CASCADE_SCALE_IMAGE
            )
            
            if width > 640:
                scale = width / 640
                stop_signs = [(int(x/scale), int(y/scale), int(w/scale), int(h/scale)) 
                             for (x, y, w, h) in stop_signs]
            
            detections = []
            for (x, y, w, h) in stop_signs:
                detections.append({
                    "type": "stop_sign",
                    "label": "stop_sign",
                    "bbox": [int(x), int(y), int(x+w), int(y+h)],
                    "center": [int(x + w//2), int(y + h//2)],
                    "confidence": 0.85,
                    "area": w * h
                })
            
            return detections
            
        except Exception as e:
            print(f"❌ Error detecting stop signs: {e}")
            return []
    
    def get_detection_json(self, frame):
        """Get detection results in JSON format with proper alert handling."""
        detections = self.detect_stop_signs(frame)
        
        if len(detections) > 0:
            self.consecutive_detections += 1
            self.last_detection_time = time.time()
        else:
            self.consecutive_detections = 0
            # Reset alert if no detections for a frame
            self.alert_active = False
        
        is_alert = self.consecutive_detections >= self.detection_threshold
        
        # Set alert state
        if is_alert:
            self.alert_active = True
        
        return {
            'alert': self.alert_active,
            'detections': detections,
            'count': len(detections),
            'consecutive_frames': self.consecutive_detections,
            'severity': 'critical' if self.alert_active else 'normal',
            'message': f'🛑 STOP SIGN DETECTED - {self.consecutive_detections} frames' if is_alert else 'No stop sign detected'
        }
    
    def reset_counter(self):
        """Reset detection counters."""
        self.consecutive_detections = 0
        self.alert_active = False
        self.last_detection_time = 0
        print("🔄 Stop sign detection counters reset")
    
    def should_process_frame(self):
        """Check if current frame should be processed (frame skipping optimization)."""
        self.frame_skip += 1
        if self.frame_skip >= self.process_every_n_frames:
            self.frame_skip = 0
            return True
        return False
