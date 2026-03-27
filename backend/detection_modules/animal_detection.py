import torch
from ultralytics import YOLO
import os

class AnimalDetection:
    COCO_ANIMALS = {
        14: 'bird', 15: 'cat', 16: 'dog', 17: 'horse', 18: 'sheep',
        19: 'cow', 20: 'elephant', 21: 'bear', 22: 'zebra', 23: 'giraffe'
    }
    
    def __init__(self, model_name="yolov8n.pt"):
        """Initialize Animal Detection with YOLO model."""
        print(f"📦 Loading animal detection model: {model_name}")
        
        try:
            self.model = YOLO(model_name)
            self.classes = self.model.names
            self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
            self.model.to(self.device)
            print(f"✅ Animal Detection initialized on {self.device}")
        except Exception as e:
            print(f"❌ Failed to load animal detection model: {e}")
            self.model = None

    def get_animal_detections(self, frame, conf_threshold=0.5):
        """Get only animal detections from frame."""
        if self.model is None:
            return []
        
        try:
            results = self.model(frame, conf=conf_threshold, verbose=False)[0]
            labels = results.boxes.cls.cpu()
            boxes = results.boxes.xyxy.cpu()
            confidences = results.boxes.conf.cpu()
            
            animal_detections = []
            for i in range(len(labels)):
                class_id = int(labels[i])
                if class_id in self.COCO_ANIMALS:
                    x1, y1, x2, y2 = map(int, boxes[i])
                    animal_detections.append({
                        "label": self.COCO_ANIMALS[class_id],
                        "class_id": class_id,
                        "bbox": [x1, y1, x2, y2],
                        "confidence": float(confidences[i])
                    })
            return animal_detections
        except Exception as e:
            print(f"❌ Error in animal detection: {e}")
            return []

    def get_detections_json(self, frame, conf_threshold=0.5):
        """Get detection results in JSON format for WebSocket (matches handler expectations)."""
        detections = self.get_animal_detections(frame, conf_threshold)
        return detections

    def is_animal_detected(self, frame, conf_threshold=0.5):
        """Quick check if any animal detected."""
        animals = self.get_animal_detections(frame, conf_threshold)
        return len(animals) > 0