import RealityKit
import Foundation

/// Top-level container for the entire neural network simulation.
struct BrainState {
    var neurons: [Neuron] = []
    var pathways: [NeuralPathway] = []
    var totalSignalsFired: Int = 0
    var peakMyelination: Float = 0.0
    var revealedNeuronCount: Int = 0
}

// MARK: - NeuroplasticityEngine

/// Calculates myelination growth using a diminishing-returns curve.
enum NeuroplasticityEngine {
    static let baseGrowthRate: Float = 0.08
    static let velocityNormalization: Float = 800.0
    static let maxStrength: Float = 1.0

    /// Returns updated myelination strength after a signal fires.
    /// Uses a diminishing-returns approach so early signals produce big jumps
    /// and later signals produce smaller incremental gains.
    static func calculateGrowth(currentStrength: Float, velocity: Float) -> Float {
        let normalizedVelocity = min(velocity / velocityNormalization, 1.5)
        let growthFactor = baseGrowthRate * max(normalizedVelocity, 0.3)
        let diminishing = 1.0 - (currentStrength / maxStrength)
        return min(currentStrength + growthFactor * diminishing, maxStrength)
    }
}
