# VectorGuard

<p align="center">
  <img src="https://github.com/galahador/VectorGuard/blob/main/VectorGuardImage.png" width="440" alt="DeviceSecurityKit" />
</p>

VectorGuard is an advanced iOS motion and sensor framework designed for real-time device behavior analysis.

# Features

- Real-time motion analysis
- Device theft / grab detection
- Suspicious movement monitoring
- Sensor fusion engine
- Background motion tracking
- Motion pattern recognition
- Orientation and stability detection
- Lightweight and optimized
- Native Swift implementation
- Easy Swift Package Manager integration

---

# Privacy Permissions

VectorGuard uses motion and heading sensors provided by Apple frameworks.

To use motion analysis and compass functionality, add the following permissions to your app’s `Info.plist`:

```xml
<key>NSMotionUsageDescription</key>
<string>Motion data is used for vector analysis.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Location and heading data are used for compass analysis.</string>

```

---

# Installation

## Swift Package Manager

```swift
.package(
    url: "https://github.com/yourname/VectorGuard.git",
    branch: "main"
)
```

---

# Quick Start

### 1. Configure and start (one call)

```swift
import VectorGuard

// AppDelegate or SwiftUI @main init()
VectorGuard.configure(autoStart: true)
```

Pass optional parameters to tune sensitivity or wire a delegate:

```swift
VectorGuard.configure(
    configuration: VectorGuardConfiguration(rapidMovementThreshold: 2.0),
    delegate: self,
    autoStart: true
)
```

### 2. Subscribe to events (supports multiple independent subscribers)

```swift
Task {
    for await event in VectorGuard.shared.subscribe() {
        switch event {
        case .devicePickedUp:
            triggerAlarm()
        case .stateChanged(_, let new):
            print("State →", new)
        case .accelerationSpike(let mag, _):
            print("Spike:", mag, "g")
        default:
            break
        }
    }
}
```

### 3. Query current status at any time

```swift
let status = VectorGuard.shared.status
print(status.currentState)       // e.g. moving(intensity: 0.43 g)
print(status.isJiggling)         // true / false
print(status.lastHeading ?? "-") // compass degrees
print(status.lastEventDate)      // when the last event fired
```

### 4. Stop monitoring

```swift
VectorGuard.shared.stopMonitoring()
```
---

It combines data from multiple hardware sensors including:

- Accelerometer
- Gyroscope
- Magnetometer
- Device Motion
- Compass
- Proximity Sensor
- Ambient Light
- Barometer

---

# Use Cases

## Security

- Detect when a device is grabbed or moved unexpectedly
- Trigger protection workflows
- Identify suspicious physical interactions

## Motion Intelligence

- Activity detection
- Movement classification
- Orientation tracking
- Stability monitoring

---

# Example Events

| Event | When it fires |
|---|---|
| `.devicePickedUp` | Device transitions from idle → moving or grabbed suddenly |
| `.devicePutDown` | Device transitions from moving/jiggling → idle |
| `.accelerationSpike(magnitude:vector:)` | Sharp linear-acceleration above threshold (grab / drop / throw) |
| `.rotationSpike(magnitude:vector:)` | Sharp angular-velocity spike (rapid twist or flip) |
| `.headingChanged(current:delta:)` | Compass heading changed beyond configured threshold |
| `.stateChanged(from:to:)` | Any motion-state transition |

Motion states exposed via `VectorGuard.shared.status.currentState`:

```swift
.idle                          // at rest
.moving(intensity: Double)     // steady movement; intensity in g
.rapidMovement(vector: SensorVector) // sudden high-g spike
.jiggling                      // repeated directional reversals
```
---

# Architecture

VectorGuard uses a multi-layer sensor fusion pipeline:

1. Raw Sensor Collection
2. Motion Normalization
3. Pattern Analysis
4. Threat Detection
5. Event Dispatching

---

# Requirements

- iOS 16+
- Swift 5.9+
- Xcode 16+

---

# Roadmap

- [ ] Machine learning motion profiles
- [ ] Watch connectivity
- [ ] Anti-theft mode
- [ ] Behavioral biometrics
- [ ] Motion anomaly scoring
- [ ] Dashboard visualizer

---

# License

MIT License

---

# Author

Petar Lemajic

Galahador 
