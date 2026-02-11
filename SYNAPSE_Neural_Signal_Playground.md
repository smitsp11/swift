# SYNAPSE — Neural Signal Playground

**Target Status:** Distinguished Winner (Swift Student Challenge 2026)  
**Deadline:** Feb 28, 2026  
**Hard Constraints:** < 25MB, Offline, 3‑Minute Experience

---

## 1. Executive Summary

**Synapse** is an interactive playground that uses computer vision to turn the user's hand into a bio‑electric spark. It visualizes the abstract concept of **Neuroplasticity** — how the brain physically changes in response to repetition.

**The “Magic” Moment:**  
The user waves their hand, and a spark travels down a 3D axon. As they repeat the motion, the axon physically grows thicker (**Myelination**) and the signal moves faster.

---

## 3. Technical Architecture & Refinements

### A. Core Stack

**Input:**  
Vision framework (`VNDetectHumanHandPoseRequest`).

**Rendering:**  
RealityKit (not SceneKit).

**Why:**  
- Better performance  
- Modern Swift API  
- Built‑in `ParticleEmitterComponent`, crucial for the visual “sparks”

**Refinement:**  
Do **not** use Canvas for particles. Use RealityKit’s native particles so they exist in true 3D space alongside the neurons.

**Audio:**  
AVAudioEngine (procedural synthesis to minimize file size).

---

### B. Data Model (Refined)

Your `Neuron` struct is solid. A `smoothVelocity` term is added at the Vision layer to reduce jitter.

```swift
// Architecture: The "Brain" Logic
struct BrainState {
    var neurons: [Neuron]
    var pathways: [NeuralPathway]
    var signalParticles: [Entity] // RealityKit entities
}

// Neuroplasticity Logic
struct NeuroplasticityEngine {
    static func calculateGrowth(currentStrength: Float, velocity: Float) -> Float {
        // Sigmoid-like growth cap to prevent infinite thickness
        // Higher velocity => stronger growth
        let growthFactor = 0.05 * (velocity / 1000.0)
        return min(currentStrength + Float(growthFactor), 1.0)
    }
}
```

---

## 5. Critical Code Snippets (RealityKit Integration)

Below is the **correct RealityKit-native approach** for rendering the visual “Spark.”  
This replaces any custom `ParticleSystem.swift` implementation.

```swift
import RealityKit
import SwiftUI

// The "Spark" is a RealityKit Entity
func createSignalSpark(color: UIColor) -> Entity {
    // 1. Create a glowing sphere
    let mesh = MeshResource.generateSphere(radius: 0.02)
    let material = UnlitMaterial(color: color)
    let spark = ModelEntity(mesh: mesh, materials: [material])
    
    // 2. Add a Trail (RealityKit ParticleEmitter)
    var particles = ParticleEmitterComponent()
    particles.timing = .repeating(
        warmUp: 0,
        emit: .frameBased,
        burstCount: 1
    )
    particles.emitterShape = .point
    particles.birthLocation = .volume
    particles.birthDirection = .local
    particles.emissionDirection = [0, 0, -1] // Trail behind spark
    particles.speed = 0.1
    
    // Visual parameters
    particles.mainEmitter.color = .constant(.init(color))
    particles.mainEmitter.size = 0.01
    particles.mainEmitter.lifeSpan = 0.5 // Short-lived trail
    
    spark.components.set(particles)
    return spark
}

// Animation: Move Spark from Neuron A to Neuron B
func fireSignal(
    from start: SIMD3<Float>,
    to end: SIMD3<Float>,
    duration: Double,
    in content: RealityViewContent
) {
    let spark = createSignalSpark(color: .cyan)
    spark.position = start
    content.add(spark)
    
    // Linear animation (upgradeable to Bezier later)
    let transform = Transform(
        scale: .one,
        rotation: .init(),
        translation: end
    )
    
    let animationDefinition = FromToByAnimation(
        to: transform,
        duration: duration,
        bindTarget: .transform
    )
    
    if let animationResource = try? AnimationResource.generate(
        with: animationDefinition
    ) {
        spark.playAnimation(animationResource)
        
        // Cleanup after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            content.remove(spark)
        }
    }
}
```

---

**End of Document**
