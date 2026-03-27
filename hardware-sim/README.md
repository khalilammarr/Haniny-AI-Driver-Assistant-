# 🛠️ Haniny Hardware Simulation

The Haniny ecosystem uses a mobile-based simulation approach to bridge the gap between vehicle telemetry and the AI Inference Engine. This allowed for rapid prototyping and testing during the hackathon.

---

## 🔌 Simulation Mechanism

| Component | Description |
| :--- | :--- |
| **Simulated OBD-II Interface** | A secondary mobile application simulates a direct connection to the vehicle's diagnostic port to extract speed, engine status, and G-force calculations. |
| **Dual-Stream Simulation** | Dual-camera feeds (driver-facing and road-facing) are captured and streamed from the simulation device. |
| **Connectivity** | Real-time data streaming via JSON over WebSockets to the Python-based FastAPI backend. |
| **Low-Latency Edge Logic** | The simulation app performs initial pre-processing to filter non-essential data before transmission. |

---

## 🏗️ Interaction Model

The simulation device interacts with the backend through the `/ws` WebSocket endpoint, sending frames encoded in Base64 for processing.

```json
{
  "camera": "driver",
  "frame": "BASE64_ENCODED_STRING"
}
```

This architecture demonstrates that the system is ready for migration to dedicated IoT hardware (e.g., Raspberry Pi or Jetson Nano with OBD-II HATs) while maintaining sub-300ms inference latency.
