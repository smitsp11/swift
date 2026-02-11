import RealityKit
import UIKit
import Combine

/// Creates and animates signal spark entities with particle trails.
@MainActor
enum SparkFactory {

    // MARK: - Spark Creation

    /// Creates a glowing sphere entity with a particle trail for the signal spark.
    static func createSpark(for pathway: NeuralPathway) -> Entity {
        let t = pathway.strength

        // 1. Glowing sphere core
        let radius: Float = 0.008 + 0.008 * t
        let mesh = MeshResource.generateSphere(radius: radius)
        let sparkColor = UIColor(
            red:   CGFloat(0.4 + 0.6 * t),
            green: CGFloat(0.8 + 0.2 * t),
            blue:  1.0,
            alpha: 1.0
        )
        let material = UnlitMaterial(color: sparkColor)
        let spark = ModelEntity(mesh: mesh, materials: [material])
        spark.name = "spark"

        // 2. Particle trail
        var particles = ParticleEmitterComponent()
        particles.emitterShape = .point
        particles.emitterShapeSize = [0.003, 0.003, 0.003]

        particles.mainEmitter.birthRate = 200 + 600 * t
        particles.mainEmitter.size = 0.003 + 0.005 * t
        particles.mainEmitter.lifeSpan = 0.3 + 0.2 * Double(t)

        particles.mainEmitter.color = .evolving(
            start: .single(sparkColor),
            end: .single(UIColor(white: 1.0, alpha: 0.0))
        )

        spark.components.set(particles)
        return spark
    }

    /// Creates a simple spark for early-phase signals (before myelination).
    static func createBasicSpark() -> Entity {
        let mesh = MeshResource.generateSphere(radius: 0.008)
        let material = UnlitMaterial(color: .cyan)
        let spark = ModelEntity(mesh: mesh, materials: [material])
        spark.name = "spark"

        var particles = ParticleEmitterComponent()
        particles.emitterShape = .point
        particles.emitterShapeSize = [0.003, 0.003, 0.003]
        particles.mainEmitter.birthRate = 200
        particles.mainEmitter.size = 0.003
        particles.mainEmitter.lifeSpan = 0.25

        particles.mainEmitter.color = .evolving(
            start: .single(.cyan),
            end: .single(UIColor(white: 1.0, alpha: 0.0))
        )

        spark.components.set(particles)
        return spark
    }

    // MARK: - Signal Animation

    /// Fires a signal spark along a pathway from source to destination.
    /// The spark animates using `move(to:)` and is cleaned up on completion.
    static func fireSignal(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        duration: Double,
        pathway: NeuralPathway,
        in anchor: Entity,
        cancellables: inout Set<AnyCancellable>,
        onArrival: @escaping @MainActor () -> Void = {}
    ) {
        let spark = createSpark(for: pathway)
        spark.position = start
        anchor.addChild(spark)

        // Animate the spark traveling along the axon
        let target = Transform(
            scale: spark.transform.scale,
            rotation: .init(),
            translation: end
        )
        spark.move(
            to: target,
            relativeTo: anchor,
            duration: duration,
            timingFunction: .easeInOut
        )

        // Listen for animation completion to clean up and trigger arrival callback
        if let scene = anchor.scene {
            scene.publisher(for: AnimationEvents.PlaybackCompleted.self, on: spark)
                .first()
                .sink { _ in
                    spark.removeFromParent()
                    onArrival()
                }
                .store(in: &cancellables)
        } else {
            // Fallback: schedule removal if scene isn't available yet
            let delay = duration + 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                spark.removeFromParent()
                onArrival()
            }
        }
    }

    /// Fires a cascade of signals across multiple pathways simultaneously.
    /// Used during the climax phase.
    static func fireCascade(
        pathways: [(start: SIMD3<Float>, end: SIMD3<Float>, pathway: NeuralPathway)],
        in anchor: Entity,
        cancellables: inout Set<AnyCancellable>,
        staggerDelay: Double = 0.08,
        onEachArrival: @escaping @MainActor (Int) -> Void = { _ in }
    ) {
        for (index, info) in pathways.enumerated() {
            let delay = Double(index) * staggerDelay

            let spark = createSpark(for: info.pathway)
            spark.position = info.start
            anchor.addChild(spark)

            let target = Transform(
                scale: spark.transform.scale,
                rotation: .init(),
                translation: info.end
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                spark.move(
                    to: target,
                    relativeTo: anchor,
                    duration: info.pathway.signalSpeed,
                    timingFunction: .easeInOut
                )
            }

            let totalDuration = delay + info.pathway.signalSpeed + 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                spark.removeFromParent()
                onEachArrival(index)
            }
        }
    }
}
