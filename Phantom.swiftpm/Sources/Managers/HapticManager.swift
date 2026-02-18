import CoreHaptics
import UIKit

@MainActor
class HapticManager: ObservableObject {
    static let shared = HapticManager()
    private var engine: CHHapticEngine?

    var isAvailable: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    func prepare() {
        guard isAvailable else { return }
        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { [weak self] reason in
                Task { @MainActor in
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
        guard engine != nil else { return }
        // Stubbed -- real haptic patterns implemented in Phase 3 (Task 3.1)
    }

    func stop() {
        engine?.stop(completionHandler: { _ in })
        engine = nil
    }
}
