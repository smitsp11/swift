import RealityKit
import UIKit

/// Creates RealityKit entities for neurons and axons.
enum NeuronFactory {

    // MARK: - Neuron Soma

    /// Creates a glowing emissive sphere representing a neuron's cell body.
    static func createNeuronEntity(
        position: SIMD3<Float>,
        radius: Float = 0.015
    ) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: radius)
        var material = UnlitMaterial(color: .cyan)
        material.color.tint = UIColor(
            red: 0.2, green: 0.8, blue: 1.0, alpha: 0.9
        )
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position
        return entity
    }

    // MARK: - Axon Cylinder

    /// Creates a cylinder entity oriented along the axis between two neuron positions.
    static func createAxonEntity(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        radius: Float = 0.003
    ) -> ModelEntity {
        let direction = end - start
        let distance = length(direction)
        guard distance > 0.001 else {
            return ModelEntity()
        }

        let mesh = MeshResource.generateCylinder(height: distance, radius: radius)
        let material = UnlitMaterial(color: UIColor(white: 0.4, alpha: 0.8))
        let axon = ModelEntity(mesh: mesh, materials: [material])

        // Position at midpoint
        axon.position = (start + end) / 2

        // Rotate from default Y-up to align with the direction vector
        let defaultUp = SIMD3<Float>(0, 1, 0)
        let normalized = normalize(direction)
        axon.orientation = simd_quatf(from: defaultUp, to: normalized)

        return axon
    }

    // MARK: - Axon Visual Update

    /// Updates an axon's appearance to reflect its current myelination level.
    /// Only regenerates the mesh when strength has changed by >= 0.1 since last regen.
    static func updateAxonVisuals(
        pathway: inout NeuralPathway,
        sourcePosition: SIMD3<Float>,
        destPosition: SIMD3<Float>
    ) {
        guard let axon = pathway.axonEntity else { return }
        let t = pathway.strength

        // Color: lerp from dim gray to bright blue-white
        let color = UIColor(
            red:   CGFloat(0.3 + 0.7 * t),
            green: CGFloat(0.5 + 0.5 * t),
            blue:  CGFloat(0.8 + 0.2 * t),
            alpha: 1.0
        )
        axon.model?.materials = [UnlitMaterial(color: color)]

        // Regenerate mesh only at significant thresholds
        let strengthDelta = abs(t - pathway.lastMeshStrength)
        if strengthDelta >= 0.08 {
            let distance = length(destPosition - sourcePosition)
            guard distance > 0.001 else { return }
            axon.model?.mesh = MeshResource.generateCylinder(
                height: distance,
                radius: pathway.axonRadius
            )
            pathway.lastMeshStrength = t
        }
    }

    // MARK: - Pulsing Activation

    /// Briefly scales a neuron entity up and back to indicate activation.
    static func pulseNeuron(_ entity: ModelEntity) {
        let scaleUp = Transform(
            scale: SIMD3<Float>(repeating: 1.5),
            rotation: entity.orientation,
            translation: entity.position
        )
        let scaleBack = Transform(
            scale: SIMD3<Float>(repeating: 1.0),
            rotation: entity.orientation,
            translation: entity.position
        )

        entity.move(to: scaleUp, relativeTo: entity.parent, duration: 0.1, timingFunction: .easeOut)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            entity.move(to: scaleBack, relativeTo: entity.parent, duration: 0.2, timingFunction: .easeInOut)
        }
    }
}
