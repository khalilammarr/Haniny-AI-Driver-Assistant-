# Hardware simulation

There was no OBD-II hardware at the hackathon, so a second phone plays the car. It reads speed and acceleration from its own sensors (G-force is computed from the accelerometer), captures a driver-facing and a road-facing camera, and streams everything to the backend's `/ws` WebSocket endpoint as JSON, with frames base64-encoded:

```json
{
  "camera": "driver",
  "frame": "BASE64_ENCODED_STRING"
}
```

Because the backend only sees this message format, the phone could be swapped for a Raspberry Pi or Jetson with an OBD-II adapter without touching the server. That swap was not built or tested.
