import SwiftUI

/// Title card and camera permission flow displayed during the onboarding phase.
struct OnboardingView: View {
    let onStart: () -> Void
    let onDemoMode: () -> Void

    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var particlePhase: Double = 0

    var body: some View {
        ZStack {
            // Dark background with subtle animated particles
            Color.black
                .ignoresSafeArea()

            // Floating particle dots
            particleBackground

            VStack(spacing: 32) {
                Spacer()

                // Title
                Text("SYNAPSE")
                    .font(.system(size: 52, weight: .ultraLight, design: .monospaced))
                    .tracking(12)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .white, .cyan.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(titleOpacity)

                Text("Neural Signal Playground")
                    .font(.system(size: 16, weight: .light, design: .default))
                    .foregroundColor(.white.opacity(0.6))
                    .opacity(titleOpacity)

                Spacer()

                // Instruction
                VStack(spacing: 16) {
                    Image(systemName: "hand.wave")
                        .font(.system(size: 40))
                        .foregroundColor(.cyan.opacity(0.8))
                        .symbolEffect(.pulse)

                    Text("Your hand is a neuron.\nWave to send a signal.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(subtitleOpacity)

                Spacer()

                // Start button
                VStack(spacing: 16) {
                    Button(action: onStart) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                            Text("Begin Experience")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(.cyan)
                        )
                    }

                    Button(action: onDemoMode) {
                        Text("Watch Demo Instead")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .opacity(buttonOpacity)

                Spacer()
                    .frame(height: 40)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                titleOpacity = 1
            }
            withAnimation(.easeIn(duration: 1.0).delay(0.8)) {
                subtitleOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.8).delay(1.5)) {
                buttonOpacity = 1
            }
        }
    }

    // MARK: - Particle Background

    private var particleBackground: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let particleCount = 30

                for i in 0..<particleCount {
                    let seed = Double(i) * 137.508 // golden angle
                    let x = (sin(time * 0.3 + seed) * 0.5 + 0.5) * size.width
                    let y = (cos(time * 0.2 + seed * 0.7) * 0.5 + 0.5) * size.height
                    let radius = 1.5 + sin(time + seed) * 1.0
                    let opacity = 0.15 + sin(time * 0.5 + seed) * 0.1

                    let rect = CGRect(
                        x: x - radius,
                        y: y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.opacity = opacity
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.cyan)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
