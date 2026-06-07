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

### 3. Vector Delegate ( print sensor response ) 

```swift
class BaseViewController: UIViewController, VectorGuardDelegate { 
    func vectorGuard(_ guard: VectorGuard, didDetect event: VectorGuardEvent) {
        switch event {
        case .accelerationSpike(let magnitude, let vector):
            print("magnitude -> \(magnitude)")
            print("vector -> \(vector)")
                        
        default: break
        }
    }
}
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
| `.devicePutDown` | Device transitions from moving/rapid-movement/jiggling → idle |
| `.accelerationSpike(magnitude:vector:)` | Sharp linear-acceleration above threshold (grab / drop / throw) |
| `.rotationSpike(magnitude:vector:)` | Sharp angular-velocity spike (rapid twist or flip) |
| `.jigglingDetected` | Repeated direction reversals — someone is shaking the device |
| `.headingChanged(current:delta:threshold:)` | Cumulative compass rotation crossed one of the configured tiers |
| `.attitudeChanged(current:delta:)` | Device orientation (pitch/roll/yaw) changed beyond threshold |
| `.altitudeChanged(delta:pressure:)` | Relative altitude changed beyond threshold (barometer) |
| `.stateChanged(from:to:)` | Any motion-state transition |

## Angle & Orientation Detection

VectorGuard tracks rotation from two independent sources, each with its own tunables:

- **Compass heading** (`headingChanged`) — absolute rotation relative to magnetic/true north.
  Raw compass readings are noisy, so VectorGuard smooths them on the unit circle (no
  discontinuity at the 0°/360° wrap) before measuring deltas — tune the strength with
  `headingSmoothingFactor` (`0...1`; lower = steadier but slower to react). Rather than a
  single on/off threshold, `headingChangeThresholds` accepts an ascending list of degree
  values (default `[15, 45, 120]`); the emitted event reports the *highest* tier the
  cumulative rotation reached, so one subscription can distinguish a small drift from a
  sharp spin via `event`'s `threshold` payload.

- **Device attitude** (`attitudeChanged`) — pitch / roll / yaw from `CMDeviceMotion`,
  exposed as ``DeviceAttitude`` (degrees). Useful for orientation changes a compass can't
  see, e.g. a phone flipped face-down or tipped out of a pocket. Fires when the combined
  per-axis change (Euclidean norm) exceeds `attitudeChangeThreshold` (default `20°`).

```swift
Task {
    for await event in VectorGuard.shared.subscribe() {
        switch event {
        case .headingChanged(let current, let delta, let threshold):
            print("Rotated \(delta)° (now \(current)°) — crossed the \(threshold)° tier")
        case .attitudeChanged(let current, _):
            print("Orientation → pitch \(current.pitch)°, roll \(current.roll)°, yaw \(current.yaw)°")
        default:
            break
        }
    }
}
```

`status.lastHeading` / `lastTrueHeading` / `lastHeadingAccuracy` and `status.lastAttitude`
expose the current readings as a point-in-time snapshot — see ``VectorGuardStatus``.

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
