# VectorGuard

<p align="center">
  <img src="https://github.com/galahador/VectorGuard/blob/main/VectorGuardImage.png" width="440" alt="DeviceSecurityKit" />
</p>

VectorGuard is an advanced iOS motion and sensor framework designed for real-time device behavior analysis.

# Features

- Real-time motion analysis (accelerometer + gyroscope fusion)
- Device theft / grab detection
- Jiggle and rapid-movement classification
- Compass heading change detection
- Barometric altitude change detection
- Multi-subscriber `AsyncStream` event API
- Raw sensor monitoring stream (`monitorSensors()`)
- Filtered event subscriptions (`subscribe(where:)`)
- Throttled sensor stream for SwiftUI (`monitorSensors(throttle:)`)
- Sensitivity presets: `.sensitive`, `.balanced`, `.relaxed`
- Point-in-time status snapshot (`VectorGuard.shared.status`)
- Zero dependencies — CoreMotion + CoreLocation only
- Native Swift, `@MainActor` safe
- Easy Swift Package Manager integration

---

# Privacy Permissions

| Sensor | Permission key |
|---|---|
| Accelerometer + Gyroscope | `NSMotionUsageDescription` |
| Barometer | None |
| Compass (heading) | `NSLocationWhenInUseUsageDescription` |

Add the relevant keys to your app’s `Info.plist`:

```xml
<!-- Required for accelerometer / gyroscope -->
<key>NSMotionUsageDescription</key>
<string>Motion data is used to detect device movement and anti-theft events.</string>

<!-- Required only if compass heading events are needed -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Heading data is used for compass analysis.</string>
```

The barometer requires no `Info.plist` key.

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
