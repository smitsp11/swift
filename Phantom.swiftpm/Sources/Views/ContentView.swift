import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var paintSession = PaintSession()

    @State private var paintingIsDemoMode = false

    var body: some View {
        ZStack {
            PhantomTheme.voidBackground.ignoresSafeArea()

            switch appViewModel.currentPhase {
            case .onboarding:
                OnboardingView(onDemo: {
                    paintSession.loadDemo()
                    paintingIsDemoMode = true
                    appViewModel.advancePhase()
                }, onBegin: {
                    paintSession.clear()
                    paintingIsDemoMode = false
                    appViewModel.advancePhase()
                })
            case .painting:
                PaintingView(isDemoMode: paintingIsDemoMode)
            case .hapticPlayback:
                HapticPlaybackView()
            case .report:
                ReportView()
            }
        }
        .environmentObject(appViewModel)
        .environmentObject(hapticManager)
        .environmentObject(paintSession)
        .onAppear {
            hapticManager.prepare()
        }
    }
}
