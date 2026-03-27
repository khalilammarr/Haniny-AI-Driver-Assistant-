import cv2
import numpy as np
import sys
import os

# Add current directory to path
sys.path.append(os.getcwd())

from detection_modules.posture_detection import PostureDetection
from detection_modules.sign_detection import StopSignDetection
from detection_modules.animal_detection import AnimalDetection

def test_detectors():
    print("🧪 Testing detection modules...")
    
    # Create a dummy black image
    frame = np.zeros((480, 640, 3), dtype=np.uint8)
    
    # 1. Test Posture Detection
    print("\n1. Testing PostureDetection...")
    try:
        posture = PostureDetection()
        # Mock model if not present (optional, but let's see if it handles missing model gracefully or if we have it)
        # The code catches exceptions during init
        
        detections = posture.get_detections_json(frame)
        print(f"✅ Posture detections: {detections}")
    except Exception as e:
        print(f"❌ Posture detection failed: {e}")
        import traceback
        traceback.print_exc()

    # 2. Test Stop Sign Detection
    print("\n2. Testing StopSignDetection...")
    try:
        sign = StopSignDetection()
        result = sign.get_detection_json(frame)
        print(f"✅ Sign result: {result}")
    except Exception as e:
        print(f"❌ Sign detection failed: {e}")
        import traceback
        traceback.print_exc()

    # 3. Test Animal Detection
    print("\n3. Testing AnimalDetection...")
    try:
        animal = AnimalDetection()
        detections = animal.get_detections_json(frame)
        print(f"✅ Animal detections: {detections}")
    except Exception as e:
        print(f"❌ Animal detection failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_detectors()
