import SwiftUI

enum AppPhase: CaseIterable, Sendable {
    case onboarding
    case painting
    case hapticPlayback
    case report
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var currentPhase: AppPhase = .onboarding

    func advancePhase() {
        let all = AppPhase.allCases
        guard let idx = all.firstIndex(of: currentPhase),
              all.index(after: idx) < all.endIndex else { return }
        currentPhase = all[all.index(after: idx)]
    }

    func goToPhase(_ phase: AppPhase) {
        currentPhase = phase
    }
}
