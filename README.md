# Haniny – AI Driver Assistant 🚗🛡️

**Empowering Road Safety through IoT, AI & Real-Time Analytics**

Developed during a hackathon in collaboration with **Lloyd Assurances**, Haniny is an AI-powered driving assistant designed to reduce accidents and support insurance risk assessment. It integrates a simulated hardware interface with a high-performance ML pipeline and a reactive Flutter mobile application.

---

## 🌟 Impact
- **InsurTech Innovation**: A seamless integration of IoT logic and AI to enable data-driven insurance decisions.
- **Real-Time Safety**: Optimized ML pipeline processing JSON streams with **sub-300ms latency** to deliver life-saving alerts.
- **Hardware Simulation**: Successfully demonstrated IoT-based safety logic using a mobile device to simulate a custom OBD-II interface.

---

## 🛠️ Key Capabilities

| Feature | Description |
| :--- | :--- |
| **Simulated Telemetry** | Captures speed, acceleration, and visual data via a mobile device acting as an OBD-II sensor. |
| **AI Driver Monitoring** | Detects fatigue, drowsy driving, smoking, and phone distraction. |
| **Road Hazard Awareness** | Identifies stop signs, animals, and potholes in the vehicle's path. |
| **SOS Emergency System** | Automatic/Manual emergency call system triggered by critical events. |
| **Insurance Scoring** | Personalized driver scores reflecting road behavior for risk assessment. |

---

## 🏗️ System Architecture

```mermaid
graph TD
    A[Hardware Simulation (Mobile)] -- "OBD-II / Images" --> B[FastAPI Backend]
    B -- "Real-Time Inference" --> C[ML Pipeline (YOLOv8 & MediaPipe)]
    C -- "WebSocket Feed" --> D[Flutter Mobile App]
    D -- "Alerts & Scoring" --> E[Driver Feedback]
    B -- "Persistent Storage" --> F[SQL Database]
    F -- "Risk Analytics" --> G[Insurance Dashboard]
```

---

## 💻 Tech Stack

- **Frontend**: Flutter (Mobile Application)
- **Backend**: Python, FastAPI, SQLAlchemy
- **Machine Learning**: YOLOv8, MediaPipe, OpenCV
- **Database**: SQLite (Development) / PostgreSQL (Production)
- **Communication**: WebSockets (Real-time telemetry & alerts)
- **Hardware Simulation**: Mobile Device acting as custom IoT Interface with simulated OBD-II support.

---

## 📂 Project Structure

- `backend/`: FastAPI server and ML detection modules (Fatigue, Smoking, Sign detection).
- `mobile_app/`: The driver-facing Flutter application.
- `hardware/`: Simulation documentation and logic for the mobile-based IoT device.
- `design/`: UI/UX prototypes and prototypes.
- `assets/`: Project branding and logos.
- `docs/`: Presentation materials and further documentation.

---

## 🚀 Getting Started

### Backend
1. `cd backend`
2. `pip install -r requirements.txt`
3. `uvicorn main:app --reload`

### Mobile App
1. `cd mobile_app`
2. `flutter pub get`
3. `flutter run`

---

## 🏆 Hackathon Achievements
Haniny was developed under tight deadlines, focusing on optimizing the ML pipeline for ultra-low latency inference to ensure that safety alerts remain viable in high-speed environments.

---

## ⚖️ License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
