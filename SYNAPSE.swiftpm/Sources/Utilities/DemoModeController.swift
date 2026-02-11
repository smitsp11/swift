import Foundation
import Combine

/// Generates synthetic hand positions to drive the SYNAPSE experience
/// when the camera is unavailable (permission denied or simulator).
///
/// The controller produces a sinusoidal wave pattern with gradually
/// increasing frequency, simulating a user discovering the wave gesture
/// and then using it with increasing confidence.
@MainActor
class DemoModeController {
    private var timer: AnyCancellable?
    private var elapsed: TimeInterval = 0
    private let tickInterval: TimeInterval = 1.0 / 30.0 // 30 Hz

    /// Current synthetic hand position (normalized, 0–1 in X and Y).
    private(set) var handPosition: SIMD3<Float> = .zero

    /// Current synthetic hand velocity magnitude.
    private(set) var handVelocity: Float = 0

    /// Whether the synthetic hand is currently performing a "wave" gesture.
    private(set) var isWaving: Bool = false

    /// Callback fired every tick with the new hand state.
    var onHandUpdate: (@MainActor (SIMD3<Float>, Float, Bool) -> Void)?

    // MARK: - Lifecycle

    func start() {
        elapsed = 0
        timer = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    // MARK: - Simulation

    private func tick() {
        elapsed += tickInterval

        // Phase 1 (0–5s): Slow discovery — gentle wave, low amplitude
        // Phase 2 (5–15s): Moderate waves — building confidence
        // Phase 3 (15–30s): Fast waves — myelination accelerating
        // Phase 4 (30s+): Intense bursts — climax cascade

        let frequency: Double
        let amplitude: Double
        let baseY: Double = 0.5

        if elapsed < 5 {
            // Discovery: slow gentle swaying
            frequency = 0.5
            amplitude = 0.08
        } else if elapsed < 15 {
            // Building: moderate waves
            let t = (elapsed - 5) / 10
            frequency = 0.5 + 1.5 * t
            amplitude = 0.08 + 0.12 * t
        } else if elapsed < 30 {
            // Growth: faster, bigger waves
            let t = (elapsed - 15) / 15
            frequency = 2.0 + 2.0 * t
            amplitude = 0.20 + 0.10 * t
        } else {
            // Climax: intense bursts
            frequency = 4.0 + sin(elapsed * 0.3) * 1.0
            amplitude = 0.30
        }

        // Sinusoidal X movement centered at 0.5
        let x = 0.5 + amplitude * sin(elapsed * frequency * 2 * .pi)
        // Slight Y oscillation for organic feel
        let y = baseY + 0.03 * sin(elapsed * frequency * .pi * 0.7)
        // Fixed Z depth
        let z: Float = -0.30

        let newPosition = SIMD3<Float>(Float(x), Float(y), z)

        // Compute velocity from position change
        let dx = newPosition.x - handPosition.x
        let dy = newPosition.y - handPosition.y
        let rawVelocity = sqrt(dx * dx + dy * dy) / Float(tickInterval)

        handPosition = newPosition
        handVelocity = rawVelocity

        // Detect "wave" as significant lateral movement
        isWaving = abs(dx) > 0.005 && rawVelocity > 50

        onHandUpdate?(handPosition, handVelocity, isWaving)
    }
}
