import Foundation

/// Exponential moving average filter to reduce jitter in Vision hand tracking.
struct VelocitySmoothing {
    private var previousPosition: SIMD3<Float>?
    private var smoothedVelocity: Float = 0
    private let smoothingFactor: Float

    init(smoothingFactor: Float = 0.3) {
        self.smoothingFactor = smoothingFactor
    }

    /// Feed in a new hand position and get back the smoothed velocity magnitude.
    mutating func update(position: SIMD3<Float>, deltaTime: Float) -> Float {
        defer { previousPosition = position }
        guard let prev = previousPosition, deltaTime > 0 else { return 0 }

        let displacement = position - prev
        let rawVelocity = length(displacement) / deltaTime
        smoothedVelocity = smoothingFactor * rawVelocity
                         + (1 - smoothingFactor) * smoothedVelocity
        return smoothedVelocity
    }

    /// Direction of movement (normalized), or zero if no previous sample.
    mutating func direction(position: SIMD3<Float>) -> SIMD3<Float> {
        guard let prev = previousPosition else { return .zero }
        let delta = position - prev
        let len = length(delta)
        return len > 0.0001 ? delta / len : .zero
    }

    mutating func reset() {
        previousPosition = nil
        smoothedVelocity = 0
    }
}
