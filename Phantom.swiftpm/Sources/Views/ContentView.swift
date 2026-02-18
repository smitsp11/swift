import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var paintSession = PaintSession()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var paintingIsDemoMode = false

    var body: some View {
        ZStack {
            PhantomTheme.voidBackground.ignoresSafeArea()

            Group {
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
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97)))
                case .painting:
                    PaintingView(isDemoMode: paintingIsDemoMode)
                        .transition(.opacity)
                case .hapticPlayback:
                    HapticPlaybackView()
                        .transition(.opacity)
                case .report:
                    ReportView()
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97)))
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .easeInOut(duration: 0.4), value: appViewModel.currentPhase)
        }
        .environmentObject(appViewModel)
        .environmentObject(hapticManager)
        .environmentObject(paintSession)
        .onAppear {
            hapticManager.prepare()
        }
    }
}
