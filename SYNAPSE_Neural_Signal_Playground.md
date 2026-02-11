# SYNAPSE — Neural Signal Playground

**Target Status:** Distinguished Winner (Swift Student Challenge 2026)  
**Deadline:** Feb 28, 2026  
**Hard Constraints:** < 25MB, Offline, 3-Minute Experience  
**Platform:** iOS 18.0+ / iPadOS 18.0+ (primary target: iPad with rear camera)

---

## 1. Executive Summary

**Synapse** is an interactive playground that uses computer vision to turn the user's hand into a bio-electric spark. It visualizes the abstract concept of **Neuroplasticity** — how the brain physically changes in response to repetition.

**The "Magic" Moment:**  
The user waves their hand, and a spark travels down a 3D axon. As they repeat the motion, the axon physically grows thicker (**Myelination**) and the signal moves faster.

---

## 2. Experience Design & User Journey

### 3-Minute Timeline

| Time      | Phase            | What Happens |
| --------- | ---------------- | ------------ |
| 0:00–0:20 | **Onboarding**   | Title card fades in. Brief text: "Your hand is a neuron. Wave to send a signal." Camera permission prompt appears. |
| 0:20–0:40 | **Discovery**    | Camera activates. A single neuron pair appears in 3D space. User sees their hand tracked on screen. A subtle pulse on the source neuron invites interaction. |
| 0:40–1:30 | **First Signals** | User waves hand — first spark fires along the axon (slow, thin trail). Each wave increments a signal counter. Audio: soft synth ping on each fire. The axon begins to thicken visibly after ~5 signals. |
| 1:30–2:20 | **Growth**       | Network expands: 2–3 more neuron pairs branch out. Faster hand motion produces stronger growth. The axon mesh thickens (myelination). Signal speed increases noticeably. Audio pitch rises with myelination level. |
| 2:20–2:50 | **Climax**       | Full network of 5–7 neurons. Signals cascade across multiple pathways simultaneously. Particle effects intensify. A "brain wave" ripple effect triggers when all pathways exceed 80% myelination. |
| 2:50–3:00 | **Reflection**   | Overlay fades in: "You just experienced neuroplasticity. Repetition physically changed your neural network." Signal count and peak myelination level displayed. |

### Onboarding Flow

1. App launches — animated title "SYNAPSE" with a subtle particle background.
2. Single instruction card: "This playground uses your camera to track hand movement."
3. System camera permission dialog triggers (`NSCameraUsageDescription`).
4. If **denied** — graceful fallback: auto-pilot demo mode with simulated hand input so the experience still works.
5. If **granted** — transition to Discovery phase with camera feed visible.

---

## 3. Technical Architecture & Refinements

### A. Core Stack

**Platform Target:** iOS 18.0+ / iPadOS 18.0+ (built with Xcode 26, Swift 6).

**Input:**  
Vision framework (`VNDetectHumanHandPoseRequest`).

**Rendering:**  
RealityKit via `ARView` (UIKit, wrapped in `UIViewRepresentable`).

**Why ARView (not standalone RealityView):**
- Provides camera passthrough automatically — no separate `AVCaptureSession` needed
- `ARSession` delivers `CVPixelBuffer` frames directly to the Vision pipeline
- RealityKit entities render in 3D overlaid on the live camera feed
- Well-tested pattern in prior SSC submissions

**Refinement:**  
Do **not** use Canvas or SpriteKit for particles. Use RealityKit's native `ParticleEmitterComponent` so particles exist in true 3D space alongside the neurons.

**Audio:**  
AVAudioEngine with procedural synthesis (see Section 3E for full design).

---

### B. Rendering Pipeline — Camera → Vision → RealityKit

```
┌──────────────────────────────────────────────────────────┐
│  ARView (UIViewRepresentable)                            │
│  ┌────────────────┐   ┌───────────────────────────────┐  │
│  │  ARSession      │──▶│  Camera Feed (auto-displayed)  │  │
│  │  (world config) │   └───────────────────────────────┘  │
│  └───────┬────────┘                                      │
│          │ currentFrame.capturedImage (CVPixelBuffer)     │
│          ▼                                               │
│  ┌────────────────────────────────────┐                  │
│  │  VNImageRequestHandler              │  (background     │
│  │  → VNDetectHumanHandPoseRequest     │   DispatchQueue)  │
│  │  → VNRecognizedPoint (2D, 0–1)      │                  │
│  └───────────────┬────────────────────┘                  │
│                  │                                       │
│                  ▼                                       │
│  ┌────────────────────────────────────┐                  │
│  │  Coordinate Mapping                 │                  │
│  │  2D normalized → 3D scene position  │                  │
│  │  (project onto plane at Z = -0.3m)  │                  │
│  └───────────────┬────────────────────┘                  │
│                  │                                       │
│                  ▼ (main queue)                          │
│  ┌────────────────────────────────────┐                  │
│  │  BrainViewModel (@Observable)       │                  │
│  │  → Update hand position             │                  │
│  │  → Detect wave gesture              │                  │
│  │  → Fire signals                     │                  │
│  │  → Apply neuroplasticity growth     │                  │
│  └───────────────┬────────────────────┘                  │
│                  │                                       │
│                  ▼                                       │
│  ┌────────────────────────────────────┐                  │
│  │  RealityKit Scene                   │                  │
│  │  → Neuron entities (spheres)        │                  │
│  │  → Axon entities (cylinders)        │                  │
│  │  → Signal sparks (particle emitter) │                  │
│  └────────────────────────────────────┘                  │
└──────────────────────────────────────────────────────────┘
```

**Coordinate Mapping Strategy:**

Vision gives normalized 2D points (0–1, origin bottom-left). To place entities in 3D AR space:

```swift
/// Maps a Vision hand landmark to a 3D position in the AR scene.
/// Falls back to projecting onto a virtual plane if raycasting fails.
func mapHandPointToScene(
    _ point: VNRecognizedPoint,
    in arView: ARView
) -> SIMD3<Float>? {
    guard point.confidence > 0.3 else { return nil }
    
    // Vision coordinates: origin at bottom-left, Y-up
    // ARView screen coordinates: origin at top-left, Y-down
    let screenX = point.location.x * CGFloat(arView.bounds.width)
    let screenY = (1 - point.location.y) * CGFloat(arView.bounds.height)
    let screenPoint = CGPoint(x: screenX, y: screenY)
    
    // Attempt ARKit raycast for real-world depth
    let results = arView.raycast(
        from: screenPoint,
        allowing: .estimatedPlane,
        alignment: .any
    )
    if let first = results.first {
        let col = first.worldTransform.columns.3
        return SIMD3<Float>(col.x, col.y, col.z)
    }
    
    // Fallback: project onto a virtual plane 0.3m in front of camera
    let camera = arView.cameraTransform
    let forward = camera.matrix.columns.2
    return camera.translation - SIMD3<Float>(forward.x, forward.y, forward.z) * 0.3
}
```

**Vision Processing (runs on a dedicated background queue):**

```swift
/// Called from the ARSession delegate on each new frame.
func processFrame(_ frame: ARFrame) {
    let handler = VNImageRequestHandler(
        cvPixelBuffer: frame.capturedImage,
        orientation: .right, // device held in portrait
        options: [:]
    )
    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 1
    
    try? handler.perform([request])
    
    guard let observation = request.results?.first else {
        DispatchQueue.main.async { self.handDetected = false }
        return
    }
    
    let wrist = try? observation.recognizedPoint(.wrist)
    let middleTip = try? observation.recognizedPoint(.middleTip)
    
    DispatchQueue.main.async {
        self.handDetected = true
        self.updateHandPosition(wrist: wrist, fingertip: middleTip)
    }
}
```

---

### C. Data Model

```swift
import RealityKit
import Foundation

// MARK: - Neuron

/// A single neuron node in the 3D neural network.
struct Neuron: Identifiable {
    let id: UUID = UUID()
    var position: SIMD3<Float>           // 3D world position of the soma
    var radius: Float = 0.015            // Visual radius of the soma sphere
    var isActive: Bool = false            // Currently firing a signal
    var activationCount: Int = 0          // Total times this neuron has fired
    var entity: ModelEntity?              // Reference to the RealityKit sphere entity
}

// MARK: - NeuralPathway

/// A connection (axon) between two neurons. Tracks myelination state.
struct NeuralPathway: Identifiable {
    let id: UUID = UUID()
    var sourceNeuronID: UUID
    var destinationNeuronID: UUID
    
    // -- Myelination / Neuroplasticity --
    var strength: Float = 0.0            // 0.0 (unmyelinated) to 1.0 (fully myelinated)
    var signalCount: Int = 0             // Number of signals that have traveled this path
    
    /// Duration in seconds for a spark to traverse this pathway.
    /// Decreases as myelination increases, simulating faster signal conduction.
    var signalSpeed: Double {
        let baseSpeed: Double = 2.0      // Slow at start (2 seconds end-to-end)
        let maxSpeed: Double = 0.3       // Fast when fully myelinated (0.3 seconds)
        return baseSpeed - (baseSpeed - maxSpeed) * Double(strength)
    }
    
    // -- Visual Representation --
    
    /// Axon cylinder radius. Thickens with myelination.
    var axonRadius: Float {
        let baseRadius: Float = 0.003
        let maxRadius: Float = 0.012
        return baseRadius + (maxRadius - baseRadius) * strength
    }
    
    var axonEntity: ModelEntity?          // The cylinder mesh connecting two neurons
}

// MARK: - BrainState

/// Top-level container for the entire neural network simulation.
struct BrainState {
    var neurons: [Neuron] = []
    var pathways: [NeuralPathway] = []
    var signalParticles: [Entity] = []    // Currently active spark entities in the scene
    var totalSignalsFired: Int = 0
    var peakMyelination: Float = 0.0      // Highest strength across all pathways
}

// MARK: - NeuroplasticityEngine

/// Calculates myelination growth using a diminishing-returns curve.
struct NeuroplasticityEngine {
    /// Base growth added per signal fire (before velocity scaling).
    static let baseGrowthRate: Float = 0.05
    /// Normalizer for raw hand velocity (points/sec) to a 0–1 range.
    static let velocityNormalization: Float = 1000.0
    /// Maximum achievable myelination strength.
    static let maxStrength: Float = 1.0
    
    /// Returns updated myelination strength after a signal fires.
    /// - Parameters:
    ///   - currentStrength: The pathway's current myelination level (0–1).
    ///   - velocity: The smoothed hand velocity at time of firing.
    /// - Returns: New myelination strength, capped at `maxStrength`.
    static func calculateGrowth(currentStrength: Float, velocity: Float) -> Float {
        let normalizedVelocity = velocity / velocityNormalization
        let growthFactor = baseGrowthRate * normalizedVelocity
        // Diminishing returns as strength approaches max (sigmoid-like)
        let diminishingMultiplier = 1.0 - (currentStrength / maxStrength)
        return min(currentStrength + growthFactor * diminishingMultiplier, maxStrength)
    }
}

// MARK: - VelocitySmoothing

/// Exponential moving average filter to reduce jitter in Vision hand tracking.
struct VelocitySmoothing {
    private var previousPosition: SIMD3<Float>?
    private var smoothedVelocity: Float = 0
    /// EMA alpha. Lower = smoother but laggier. 0.3 is a good balance.
    private let smoothingFactor: Float = 0.3
    
    /// Feed in a new hand position and get back the smoothed velocity.
    mutating func update(position: SIMD3<Float>, deltaTime: Float) -> Float {
        defer { previousPosition = position }
        guard let prev = previousPosition, deltaTime > 0 else { return 0 }
        
        let rawVelocity = length(position - prev) / deltaTime
        smoothedVelocity = smoothingFactor * rawVelocity
                         + (1 - smoothingFactor) * smoothedVelocity
        return smoothedVelocity
    }
    
    mutating func reset() {
        previousPosition = nil
        smoothedVelocity = 0
    }
}
```

**Neuron Layout Strategy:**

Neurons are placed in a predefined branching layout, revealed progressively as the experience advances through phases:

```swift
/// Predefined neuron positions forming a branching network.
/// Coordinates are in meters, relative to the scene anchor.
enum NetworkLayout {
    struct NodeDef {
        let position: SIMD3<Float>
        let connections: [Int]  // Indices of destination neurons
    }
    
    // Phase 1: Initial pair (revealed during Discovery, 0:20)
    // Phase 2: First branch (revealed during Growth, 1:30)
    // Phase 3: Full network (revealed during Climax, 2:20)
    
    static let nodes: [NodeDef] = [
        // -- Phase 1 --
        NodeDef(position: SIMD3(-0.08,  0.00, -0.30), connections: [1]),    // 0: Source
        NodeDef(position: SIMD3( 0.08,  0.00, -0.30), connections: [2, 3]), // 1: First target
        // -- Phase 2 --
        NodeDef(position: SIMD3( 0.18,  0.06, -0.30), connections: [4]),    // 2: Upper branch
        NodeDef(position: SIMD3( 0.18, -0.06, -0.30), connections: [5]),    // 3: Lower branch
        // -- Phase 3 --
        NodeDef(position: SIMD3( 0.28,  0.10, -0.30), connections: []),     // 4: Upper leaf
        NodeDef(position: SIMD3( 0.28, -0.10, -0.30), connections: [6]),    // 5: Lower mid
        NodeDef(position: SIMD3( 0.38,  0.00, -0.30), connections: []),     // 6: Terminal
    ]
    
    static let phaseReveal: [Int] = [2, 4, 7] // Neuron count revealed per phase
}
```

**Axon Mesh Generation:**

Axons are rendered as cylinders connecting two neuron positions:

```swift
/// Creates a cylinder entity oriented along the axis between two points.
func createAxonEntity(
    from start: SIMD3<Float>,
    to end: SIMD3<Float>,
    radius: Float
) -> ModelEntity {
    let direction = end - start
    let distance = length(direction)
    
    let mesh = MeshResource.generateCylinder(height: distance, radius: radius)
    let material = UnlitMaterial(color: .init(white: 0.4, alpha: 0.8))
    let axon = ModelEntity(mesh: mesh, materials: [material])
    
    // Position at the midpoint between source and destination
    axon.position = (start + end) / 2
    
    // Rotate the default Y-up cylinder to align with the connection direction
    let defaultUp = SIMD3<Float>(0, 1, 0)
    axon.orientation = simd_quatf(from: defaultUp, to: normalize(direction))
    
    return axon
}
```

---

### D. State Management Architecture

```swift
import SwiftUI
import RealityKit
import ARKit
import Vision
import Combine

@Observable
class BrainViewModel {
    // -- Published state (drives SwiftUI) --
    var brainState = BrainState()
    var handDetected: Bool = false
    var currentPhase: ExperiencePhase = .onboarding
    var elapsedTime: TimeInterval = 0
    
    // -- Internal --
    private var velocityTracker = VelocitySmoothing()
    private var cancellables = Set<AnyCancellable>()
    private var lastFrameTime: Date = .now
    private let visionQueue = DispatchQueue(
        label: "com.synapse.vision",
        qos: .userInteractive
    )
    
    enum ExperiencePhase: CaseIterable {
        case onboarding    // 0:00–0:20
        case discovery     // 0:20–0:40
        case firstSignals  // 0:40–1:30
        case growth        // 1:30–2:20
        case climax        // 2:20–2:50
        case reflection    // 2:50–3:00
    }
    
    // MARK: - Vision Processing
    
    /// Called from ARSessionDelegate.session(_:didUpdate:) on every new frame.
    func processARFrame(_ frame: ARFrame) {
        visionQueue.async { [weak self] in
            self?.runHandDetection(on: frame)
        }
    }
    
    private func runHandDetection(on frame: ARFrame) {
        let handler = VNImageRequestHandler(
            cvPixelBuffer: frame.capturedImage,
            orientation: .right,
            options: [:]
        )
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        
        try? handler.perform([request])
        
        guard let observation = request.results?.first,
              let wrist = try? observation.recognizedPoint(.wrist),
              let middleTip = try? observation.recognizedPoint(.middleTip) else {
            DispatchQueue.main.async { self.handDetected = false }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.handDetected = true
            self?.updateHandPosition(wrist: wrist, fingertip: middleTip)
        }
    }
    
    // MARK: - Signal Firing (main queue only)
    
    @MainActor
    func fireSignalIfReady(velocity: Float) {
        // Require minimum gesture speed to prevent accidental fires
        guard velocity > 100 else { return }
        guard let pathway = nextFirablePathway() else { return }
        
        // Apply neuroplasticity growth
        let newStrength = NeuroplasticityEngine.calculateGrowth(
            currentStrength: pathway.strength,
            velocity: velocity
        )
        updatePathwayStrength(pathway.id, to: newStrength)
        brainState.totalSignalsFired += 1
        brainState.peakMyelination = max(
            brainState.peakMyelination,
            newStrength
        )
    }
    
    // MARK: - Phase Management
    
    @MainActor
    func advancePhaseIfNeeded() {
        switch currentPhase {
        case .onboarding where elapsedTime >= 20:
            currentPhase = .discovery
            revealNeurons(count: NetworkLayout.phaseReveal[0])
        case .discovery where elapsedTime >= 40:
            currentPhase = .firstSignals
        case .firstSignals where elapsedTime >= 90:
            currentPhase = .growth
            revealNeurons(count: NetworkLayout.phaseReveal[1])
        case .growth where elapsedTime >= 140:
            currentPhase = .climax
            revealNeurons(count: NetworkLayout.phaseReveal[2])
        case .climax where elapsedTime >= 170:
            currentPhase = .reflection
        default:
            break
        }
    }
    
    // ... additional helper methods: nextFirablePathway(), updatePathwayStrength(),
    //     revealNeurons(), updateHandPosition()
}
```

**Thread Safety Rule:**  
Vision runs on the dedicated `visionQueue`. **All** RealityKit entity mutations and `@Observable` property writes happen on the main actor. Use `DispatchQueue.main.async` or `@MainActor` annotations to cross the boundary. Never mutate entities from the vision queue.

---

### E. Audio Design — Procedural Synthesis

**Engine:** `AVAudioEngine` with `AVAudioSourceNode` for real-time waveform generation.  
**Size Impact:** Zero audio files. All sound is generated at runtime (~2 KB of code).

**Sound Events:**

| Event                 | Sound Design |
| --------------------- | ------------ |
| Signal fires          | Short sine-wave "ping" at `220 + 440 * strength` Hz. 0.15s attack, 0.15s decay. |
| Spark reaches target  | Soft harmonic chime (fundamental + 3rd + 5th overtones). 0.2s decay. |
| Myelination threshold | Low resonant "bloom" (80 Hz sine, 0.5s fade-in). Triggers at 25%, 50%, 75%, 100% strength. |
| Cascade (climax)      | Layered arpeggiated tones, one per active pathway, quantized to pentatonic scale. |

**Implementation:**

```swift
import AVFoundation

class SynapseAudioEngine {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var currentFrequency: Float = 0
    private var amplitude: Float = 0
    private var phase: Float = 0
    
    func setup() throws {
        let sampleRate: Double = 44100
        let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        )!
        
        sourceNode = AVAudioSourceNode(format: format) {
            [weak self] _, _, frameCount, bufferList in
            guard let self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            let buffer = ablPointer[0]
            let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
            
            for i in 0..<Int(frameCount) {
                ptr[i] = sin(self.phase * 2.0 * .pi) * self.amplitude
                self.phase += self.currentFrequency / Float(sampleRate)
                if self.phase > 1.0 { self.phase -= 1.0 }
            }
            return noErr
        }
        
        engine.attach(sourceNode!)
        engine.connect(sourceNode!, to: engine.mainMixerNode, format: format)
        try engine.start()
    }
    
    /// Plays a short ping whose pitch reflects the pathway's myelination level.
    func playSignalPing(myelinationStrength: Float) {
        currentFrequency = 220 + 440 * myelinationStrength
        amplitude = 0.3
        
        // Simple envelope: decay over 0.3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.amplitude = 0
            self?.currentFrequency = 0
        }
    }
}
```

---

## 4. Visual & UX Design

### Scene Layout

The neural network is positioned on a virtual plane approximately 30 cm in front of the camera. Neurons are rendered as emissive spheres (`UnlitMaterial`, cyan/blue palette). Axons are thin cylinders connecting them. The live camera feed is visible behind the 3D scene, provided automatically by `ARView`.

### Myelination Visualization

As `pathway.strength` increases from 0.0 to 1.0, four visual properties change simultaneously:

1. **Axon thickness:** Cylinder radius scales from 0.003 m to 0.012 m (mesh regenerated).
2. **Axon color:** Transitions from dim gray (unmyelinated) to bright white-blue (fully myelinated) via `UnlitMaterial` color interpolation.
3. **Signal speed:** Spark traversal duration decreases from 2.0 s to 0.3 s.
4. **Particle intensity:** Spark trail `birthRate` increases from 200 to 800 particles/sec.

```swift
/// Updates the axon's visual appearance to reflect its current myelination level.
func updateAxonVisuals(
    pathway: NeuralPathway,
    sourcePosition: SIMD3<Float>,
    destPosition: SIMD3<Float>
) {
    guard let axon = pathway.axonEntity else { return }
    let t = pathway.strength // 0.0 – 1.0
    
    // Color: lerp from dim gray to bright blue-white
    let color = UIColor(
        red:   CGFloat(0.3 + 0.7 * t),
        green: CGFloat(0.5 + 0.5 * t),
        blue:  CGFloat(0.8 + 0.2 * t),
        alpha: 1.0
    )
    axon.model?.materials = [UnlitMaterial(color: color)]
    
    // Thickness: regenerate cylinder with updated radius
    let distance = length(destPosition - sourcePosition)
    axon.model?.mesh = MeshResource.generateCylinder(
        height: distance,
        radius: pathway.axonRadius
    )
}
```

### Error States

| State                     | User-Facing Behavior |
| ------------------------- | -------------------- |
| Camera permission denied  | Switch to **demo mode**: simulated hand input drives the same full experience automatically. |
| Hand leaves camera frame  | Pulsing border glow + text: "Move your hand back into view." Neurons remain visible, signals pause. |
| Hand not detected (> 3 s) | Gentle hint overlay: "Try holding your hand flat, palm facing the camera." |
| AR tracking lost          | Brief "Recalibrating..." overlay. Resume automatically when tracking recovers. |

### Accessibility

- **VoiceOver:** Announce signal events via `UIAccessibility.post(notification:argument:)` — e.g., "Signal fired. Pathway strength: 40 percent."
- **Reduced Motion:** Check `UIAccessibility.isReduceMotionEnabled`. If true, replace particle trails with simple color flashes on the axon and reduce animation speed by 50%.
- **Dynamic Type:** All overlay text (onboarding, reflection, hints) uses SwiftUI `Text` with `.font(.body)`, which respects Dynamic Type automatically.
- **Color Independence:** Myelination progress is conveyed primarily through **thickness change** (not color alone), ensuring the visualization is meaningful for color-blind users.

---

## 5. Critical Code Snippets (RealityKit Integration)

Below is the **correct RealityKit-native approach** for rendering the visual "Spark," verified against the `ParticleEmitterComponent` API available on iOS 17+.

```swift
import RealityKit
import SwiftUI
import Combine

// MARK: - Spark Creation

/// Creates a glowing sphere entity with a particle trail for the signal spark.
func createSignalSpark(color: UIColor = .cyan) -> Entity {
    // 1. Glowing sphere core
    let mesh = MeshResource.generateSphere(radius: 0.02)
    let material = UnlitMaterial(color: color)
    let spark = ModelEntity(mesh: mesh, materials: [material])
    
    // 2. Particle trail using verified ParticleEmitterComponent API
    var particles = ParticleEmitterComponent()
    particles.emitterShape = .point
    particles.emitterShapeSize = [0.005, 0.005, 0.005]
    
    // Emission rate and lifetime
    particles.mainEmitter.birthRate = 500
    particles.mainEmitter.size = 0.005
    particles.mainEmitter.lifeSpan = 0.4
    
    // Color: evolve from spark color to fully transparent
    particles.mainEmitter.color = .evolving(
        start: .single(.init(color)),
        end: .single(.init(UIColor(white: 1.0, alpha: 0.0)))
    )
    
    spark.components.set(particles)
    return spark
}

/// Variant that scales particle intensity based on myelination level.
func createSignalSpark(for pathway: NeuralPathway) -> Entity {
    let spark = createSignalSpark()
    
    if var particles = spark.components[ParticleEmitterComponent.self] {
        let t = pathway.strength
        particles.mainEmitter.birthRate = 200 + 600 * t    // 200 → 800
        particles.mainEmitter.size = 0.003 + 0.007 * t     // grows with strength
        spark.components.set(particles)
    }
    
    return spark
}

// MARK: - Signal Animation

/// Fires a signal spark along a pathway with proper animation and cleanup.
/// Uses `entity.move(to:)` and animation-completion publishers instead of
/// DispatchQueue.main.asyncAfter for reliable lifecycle management.
func fireSignal(
    from start: SIMD3<Float>,
    to end: SIMD3<Float>,
    duration: Double,
    in sceneAnchor: Entity,
    cancellables: inout Set<AnyCancellable>
) {
    let spark = createSignalSpark()
    spark.position = start
    sceneAnchor.addChild(spark)
    
    // Animate using move(to:) — simpler and more reliable than FromToByAnimation
    let target = Transform(scale: .one, rotation: .init(), translation: end)
    spark.move(
        to: target,
        relativeTo: sceneAnchor,
        duration: duration,
        timingFunction: .easeInOut
    )
    
    // Clean up the spark entity when the animation finishes
    if let scene = sceneAnchor.scene {
        scene.publisher(for: AnimationEvents.PlaybackCompleted.self, on: spark)
            .first()
            .sink { _ in
                spark.removeFromParent()
            }
            .store(in: &cancellables)
    }
}
```

---

## 6. Submission & Project Structure

### Package.swift (.swiftpm format)

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SYNAPSE",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .iOSApplication(
            name: "SYNAPSE",
            targets: ["SYNAPSE"],
            bundleIdentifier: "com.yourname.synapse",
            teamIdentifier: "YOUR_TEAM_ID",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .brain),
            accentColor: .presetColor(.cyan),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [.portrait],
            capabilities: [
                .camera(purposeString:
                    "SYNAPSE uses your camera to track hand movements "
                  + "and visualize neural signals in real time."
                )
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "SYNAPSE",
            path: "Sources"
        )
    ]
)
```

### Project File Layout

```
SYNAPSE.swiftpm/
├── Package.swift
├── Sources/
│   ├── SYNAPSEApp.swift              // @main App entry point
│   ├── ContentView.swift              // Root view: phase router
│   │
│   ├── Views/
│   │   ├── OnboardingView.swift       // Title card + permission request
│   │   ├── ARExperienceView.swift     // ARView wrapper (UIViewRepresentable)
│   │   └── ReflectionView.swift       // End summary with stats
│   │
│   ├── Models/
│   │   ├── Neuron.swift               // Neuron struct
│   │   ├── NeuralPathway.swift        // NeuralPathway struct
│   │   ├── BrainState.swift           // BrainState + NeuroplasticityEngine
│   │   └── VelocitySmoothing.swift    // EMA velocity tracker
│   │
│   ├── ViewModels/
│   │   └── BrainViewModel.swift       // @Observable — owns all state + logic
│   │
│   ├── RealityKit/
│   │   ├── SparkFactory.swift         // createSignalSpark(), fireSignal()
│   │   ├── NeuronFactory.swift        // createNeuronEntity(), createAxonEntity()
│   │   └── SceneBuilder.swift         // Assembles initial scene from NetworkLayout
│   │
│   ├── Audio/
│   │   └── SynapseAudioEngine.swift   // Procedural synthesis via AVAudioEngine
│   │
│   └── Utilities/
│       └── CoordinateMapping.swift    // Vision 2D → RealityKit 3D projection
│
└── Resources/
    └── (empty — all assets are procedural)
```

### Size Budget

| Component              | Estimated Size |
| ---------------------- | -------------- |
| Compiled Swift code    | ~3–5 MB        |
| RealityKit runtime     | 0 MB (system framework, not bundled) |
| Audio files            | 0 MB (procedural synthesis)          |
| Textures / 3D models   | 0 MB (all generated via `MeshResource`) |
| App metadata           | ~0.1 MB        |
| **Total**              | **~3–5 MB** (well under the 25 MB limit) |

### Compatibility Checklist

- [ ] Built with Xcode 26 and Swift 6
- [ ] Runs on Swift Playgrounds 4.6
- [ ] Minimum deployment target: iOS 18.0
- [ ] All APIs used are stable: `ARView` (iOS 13+), `VNDetectHumanHandPoseRequest` (iOS 14+), `ParticleEmitterComponent` (iOS 17+), `@Observable` (iOS 17+)
- [ ] No third-party dependencies — Apple frameworks only
- [ ] Works fully offline — no network calls
- [ ] Tested on physical iPad (camera required for full experience)
- [ ] Simulator fallback: demo mode activates automatically when camera is unavailable

---

**End of Document**
