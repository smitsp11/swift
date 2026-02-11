import RealityKit
import Foundation

/// A single neuron node in the 3D neural network.
struct Neuron: Identifiable {
    let id: UUID
    var position: SIMD3<Float>
    var radius: Float
    var isActive: Bool
    var activationCount: Int
    var entity: ModelEntity?

    init(
        id: UUID = UUID(),
        position: SIMD3<Float>,
        radius: Float = 0.015,
        isActive: Bool = false,
        activationCount: Int = 0,
        entity: ModelEntity? = nil
    ) {
        self.id = id
        self.position = position
        self.radius = radius
        self.isActive = isActive
        self.activationCount = activationCount
        self.entity = entity
    }
}
