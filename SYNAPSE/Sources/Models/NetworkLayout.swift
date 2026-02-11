import Foundation

/// Predefined neuron positions forming a branching network.
/// Coordinates are in meters, relative to the scene anchor.
enum NetworkLayout {
    struct NodeDef {
        let position: SIMD3<Float>
        let connections: [Int]  // Indices of destination neurons
    }

    // Phase 1: Initial pair (Discovery)
    // Phase 2: First branch (Growth)
    // Phase 3: Full network (Climax)
    static let nodes: [NodeDef] = [
        // -- Phase 1: indices 0–1 --
        NodeDef(position: SIMD3(-0.08,  0.00, -0.30), connections: [1]),
        NodeDef(position: SIMD3( 0.08,  0.00, -0.30), connections: [2, 3]),
        // -- Phase 2: indices 2–3 --
        NodeDef(position: SIMD3( 0.18,  0.06, -0.30), connections: [4]),
        NodeDef(position: SIMD3( 0.18, -0.06, -0.30), connections: [5]),
        // -- Phase 3: indices 4–6 --
        NodeDef(position: SIMD3( 0.28,  0.10, -0.30), connections: []),
        NodeDef(position: SIMD3( 0.28, -0.10, -0.30), connections: [6]),
        NodeDef(position: SIMD3( 0.38,  0.00, -0.30), connections: []),
    ]

    /// How many neurons are revealed at each phase boundary.
    /// Phase 1 reveals 2, Phase 2 reveals 4, Phase 3 reveals all 7.
    static let phaseReveal: [Int] = [2, 4, 7]

    /// Signal count thresholds that trigger the next phase.
    /// Phase transitions happen when totalSignalsFired exceeds these values
    /// OR when the time-based fallback is hit.
    static let signalThresholds: [Int] = [0, 1, 5, 15, 30]
}
