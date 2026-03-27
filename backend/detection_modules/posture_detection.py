import torch
from ultralytics import YOLO

class PostureDetection:
    def __init__(self, model_name="yolov8n.pt"):
        """Initialize posture detection with YOLO model."""
        print(f"📦 Loading posture detection model: {model_name}")
        
        try:
            self.model = YOLO(model_name)
            self.classes = self.model.names
            self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
            print(f'✅ Using Device: {self.device}')
        except Exception as e:
            print(f"❌ Failed to load posture model: {e}")
            self.model = None
    
    def get_postures(self, frame, min_confidence=0.2):
        """Get detected posture issues."""
        if self.model is None:
            return []
            
        try:
            results = self.model(frame, conf=min_confidence, verbose=False)[0]
            labels = results.boxes.cls.cpu()
            boxes = results.boxes.xyxy.cpu()
            confidences = results.boxes.conf.cpu()
            
            postures = []
            
            for i in range(len(labels)):
                class_id = int(labels[i])
                x1, y1, x2, y2 = map(int, boxes[i])
                confidence = float(confidences[i])
                
                posture_type = self.classes.get(class_id, "Unknown")
                postures.append({
                    "type": posture_type,
                    "label": posture_type, # handler expects 'label'
                    "bbox": [x1, y1, x2, y2],
                    "label_id": class_id,
                    "confidence": confidence
                })
            
            return postures
        except Exception as e:
            print(f"❌ Error in posture detection: {e}")
            return []
    
    def get_detections_json(self, frame, min_confidence=0.2):
        """Get detection results in JSON format for WebSocket."""
        return self.get_postures(frame, min_confidence)

    def is_bad_posture_detected(self, frame, min_confidence=0.2):
        """Check if bad posture detected."""
        postures = self.get_postures(frame, min_confidence)
        return len(postures) > 0
