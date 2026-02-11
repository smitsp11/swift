import SwiftUI
import AVFoundation

/// Root view that routes between experience phases.
/// Manages camera permission flow and transitions between
/// onboarding, the AR experience, and the reflection screen.
struct ContentView: View {
    @State private var viewModel = BrainViewModel()
    @State private var showAR = false

    var body: some View {
        ZStack {
            // AR experience layer (always present once started, behind overlays)
            if showAR {
                ARExperienceView(viewModel: viewModel)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Phase-dependent overlay
            switch viewModel.currentPhase {
            case .onboarding:
                if !showAR {
                    OnboardingView(
                        onStart: { requestCameraAndStart() },
                        onDemoMode: { startDemoMode() }
                    )
                    .transition(.opacity)
                }

            case .discovery, .firstSignals, .growth, .climax:
                // HUD overlay on top of AR
                experienceHUD
                    .transition(.opacity)

            case .reflection:
                ReflectionView(
                    totalSignals: viewModel.brainState.totalSignalsFired,
                    peakMyelination: viewModel.brainState.peakMyelination,
                    onRestart: { restartExperience() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: viewModel.currentPhase)
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }

    // MARK: - Experience HUD

    /// Minimal heads-up display shown during the active AR experience.
    private var experienceHUD: some View {
        VStack {
            HStack {
                // Phase indicator
                phaseLabel
                Spacer()
                // Signal counter
                signalCounter
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            // Hand detection hint
            if !viewModel.handDetected && !viewModel.isDemoMode {
                handHint
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 40)
            }

            // Myelination progress bar
            if viewModel.currentPhase != .discovery {
                myelinationBar
                    .padding(.horizontal, 40)
                    .padding(.bottom, 24)
            }
        }
        .allowsHitTesting(false)
    }

    private var phaseLabel: some View {
        Text(phaseDisplayName)
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundColor(.cyan.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.black.opacity(0.4))
            )
    }

    private var signalCounter: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12))
                .foregroundColor(.cyan)
            Text("\(viewModel.brainState.totalSignalsFired)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.black.opacity(0.4))
        )
    }

    private var handHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised")
                .symbolEffect(.pulse)
            Text("Show your hand to the camera")
                .font(.subheadline)
        }
        .foregroundColor(.white.opacity(0.7))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.black.opacity(0.5))
        )
    }

    private var myelinationBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(.white.opacity(0.1))
                        .frame(height: 4)

                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(viewModel.brainState.peakMyelination),
                            height: 4
                        )
                        .animation(.easeOut(duration: 0.3), value: viewModel.brainState.peakMyelination)
                }
            }
            .frame(height: 4)

            Text("Myelination: \(Int(viewModel.brainState.peakMyelination * 100))%")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var phaseDisplayName: String {
        switch viewModel.currentPhase {
        case .onboarding: return "READY"
        case .discovery: return "DISCOVER"
        case .firstSignals: return "SIGNAL"
        case .growth: return "GROWTH"
        case .climax: return "CASCADE"
        case .reflection: return "REFLECT"
        }
    }

    // MARK: - Actions

    private func requestCameraAndStart() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    startARExperience()
                } else {
                    startDemoMode()
                }
            }
        }
    }

    private func startARExperience() {
        withAnimation {
            showAR = true
        }
        viewModel.startExperience()
    }

    private func startDemoMode() {
        withAnimation {
            showAR = true
        }
        viewModel.startDemoMode()
    }

    private func restartExperience() {
        viewModel.stopExperience()
        viewModel = BrainViewModel()
        showAR = false
    }
}
