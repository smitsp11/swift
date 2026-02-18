import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var hapticManager = HapticManager.shared

    var body: some View {
        ZStack {
            PhantomTheme.voidBackground.ignoresSafeArea()

            switch appViewModel.currentPhase {
            case .onboarding:
                OnboardingView()
            case .painting:
                PaintingView()
            case .hapticPlayback:
                HapticPlaybackView()
            case .report:
                ReportView()
            }
        }
        .environmentObject(appViewModel)
        .environmentObject(hapticManager)
        .onAppear {
            hapticManager.prepare()
        }
    }
}
