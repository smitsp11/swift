import CoreHaptics
import UIKit

@MainActor
class HapticManager: ObservableObject {
    static let shared = HapticManager()
    private var engine: CHHapticEngine?
    private var currentPlayer: CHHapticPatternPlayer?
    private var lastPlayTime: TimeInterval = 0
    private static let cooldownInterval: TimeInterval = 0.05

    @Published var activeTexture: PainTexture?

    var isAvailable: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    func prepare() {
        guard isAvailable else { return }
        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { [weak self] _ in
                Task { @MainActor in
                    self?.currentPlayer = nil
                    self?.activeTexture = nil
                    self?.prepare()
                }
            }
            engine?.resetHandler = { [weak self] in
                Task { @MainActor in
                    try? self?.engine?.start()
                }
            }
            try engine?.start()
        } catch {
            print("[HapticManager] Engine start failed: \(error)")
        }
    }

    func playTexture(_ texture: PainTexture, intensity: Float = 1.0) {
        guard let engine = engine else { return }

        let now = CACurrentMediaTime()
        guard now - lastPlayTime >= Self.cooldownInterval else { return }
        lastPlayTime = now

        stopCurrentPattern()

        let clampedIntensity = max(0.1, min(1.0, intensity))
        let events = hapticEvents(for: texture, intensity: clampedIntensity)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            currentPlayer = player
            try player.start(atTime: CHHapticTimeImmediate)
            activeTexture = texture
        } catch {
            print("[HapticManager] Play failed: \(error)")
        }
    }

    func stopCurrentPattern() {
        try? currentPlayer?.stop(atTime: CHHapticTimeImmediate)
        currentPlayer = nil
        activeTexture = nil
    }

    func stop() {
        stopCurrentPattern()
        engine?.stop(completionHandler: { _ in })
        engine = nil
    }

    // MARK: - Haptic Pattern Definitions

    private func hapticEvents(for texture: PainTexture, intensity: Float) -> [CHHapticEvent] {
        switch texture {
        case .burning:
            return burningEvents(intensity: intensity)
        case .electric:
            return electricEvents(intensity: intensity)
        case .pinsAndNeedles:
            return pinsAndNeedlesEvents(intensity: intensity)
        }
    }

    private func burningEvents(intensity: Float) -> [CHHapticEvent] {
        let params = [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8 * intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
        ]
        return [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: params,
                relativeTime: 0,
                duration: 0.3
            )
        ]
    }

    private func electricEvents(intensity: Float) -> [CHHapticEvent] {
        let offsets: [TimeInterval] = [0, 0.08, 0.18, 0.26, 0.38]
        return offsets.map { offset in
            let params = [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9 * intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ]
            return CHHapticEvent(
                eventType: .hapticTransient,
                parameters: params,
                relativeTime: offset
            )
        }
    }

    private func pinsAndNeedlesEvents(intensity: Float) -> [CHHapticEvent] {
        let params = [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4 * intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.95)
        ]
        return [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: params,
                relativeTime: 0,
                duration: 0.2
            )
        ]
    }
}
