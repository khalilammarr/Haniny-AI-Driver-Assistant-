import torch
import cv2
from ultralytics import YOLO

class RoadDamageDetection:
    def __init__(self, model_name="yolov8n.pt"):
        """Initialize road damage detection with YOLO model."""
        print(f"📦 Loading road damage detection model: {model_name}")
        
        try:
            self.model = YOLO(model_name)
            self.classes = self.model.names
            self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
            print(f'✅ Using Device: {self.device}')
        except Exception as e:
            print(f"❌ Failed to load road damage model: {e}")
            self.model = None
    
    def get_damages(self, frame, min_confidence=0.2):
        """Get detected road damages."""
        if self.model is None:
            return []

        try:
            results = self.model(frame, conf=min_confidence, verbose=False)[0]
            labels = results.boxes.cls.cpu()
            boxes = results.boxes.xyxy.cpu()
            confidences = results.boxes.conf.cpu()
            
            damages = []
            
            for i in range(len(labels)):
                class_id = int(labels[i])
                x1, y1, x2, y2 = map(int, boxes[i])
                confidence = float(confidences[i])
                
                damage_type = self.classes.get(class_id, "Unknown")
                damages.append({
                    "type": damage_type,
                    "label": damage_type,
                    "bbox": [x1, y1, x2, y2],
                    "label_id": class_id,
                    "confidence": confidence
                })
            
            return damages
        except Exception as e:
            print(f"❌ Error in road damage detection: {e}")
            return []

    def is_damage_detected(self, frame, min_confidence=0.2):
        """Check if any road damage detected."""
        damages = self.get_damages(frame, min_confidence)
        return len(damages) > 0
