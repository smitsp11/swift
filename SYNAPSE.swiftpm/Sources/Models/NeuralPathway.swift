import RealityKit
import Foundation

/// A connection (axon) between two neurons. Tracks myelination state.
struct NeuralPathway: Identifiable {
    let id: UUID
    var sourceNeuronID: UUID
    var destinationNeuronID: UUID

    // -- Myelination / Neuroplasticity --
    var strength: Float = 0.0          // 0.0 (unmyelinated) to 1.0 (fully myelinated)
    var signalCount: Int = 0           // Number of signals that have traveled this path

    /// Duration in seconds for a spark to traverse this pathway.
    /// Decreases as myelination increases, simulating faster signal conduction.
    var signalSpeed: Double {
        let baseSpeed: Double = 2.0
        let maxSpeed: Double = 0.3
        return baseSpeed - (baseSpeed - maxSpeed) * Double(strength)
    }

    /// Axon cylinder radius. Thickens with myelination.
    var axonRadius: Float {
        let baseRadius: Float = 0.003
        let maxRadius: Float = 0.012
        return baseRadius + (maxRadius - baseRadius) * strength
    }

    var axonEntity: ModelEntity?

    /// The last strength value at which we regenerated the mesh.
    /// Used to batch visual updates and avoid regenerating every frame.
    var lastMeshStrength: Float = 0.0

    init(
        id: UUID = UUID(),
        sourceNeuronID: UUID,
        destinationNeuronID: UUID,
        axonEntity: ModelEntity? = nil
    ) {
        self.id = id
        self.sourceNeuronID = sourceNeuronID
        self.destinationNeuronID = destinationNeuronID
        self.axonEntity = axonEntity
    }
}
