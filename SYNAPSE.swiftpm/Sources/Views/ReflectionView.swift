import SwiftUI

/// End-of-experience summary displaying neuroplasticity insights and stats.
struct ReflectionView: View {
    let totalSignals: Int
    let peakMyelination: Float
    let onRestart: () -> Void

    @State private var textOpacity: Double = 0
    @State private var statsOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            // Semi-transparent overlay so the AR scene is still faintly visible
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Main message
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundColor(.cyan)

                    Text("You just experienced\nneuroplasticity.")
                        .font(.title2)
                        .fontWeight(.light)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)

                    Text("Repetition physically changed\nyour neural network.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(textOpacity)

                // Stats
                HStack(spacing: 40) {
                    statCard(
                        value: "\(totalSignals)",
                        label: "Signals Fired",
                        icon: "bolt.fill"
                    )
                    statCard(
                        value: "\(Int(peakMyelination * 100))%",
                        label: "Peak Myelination",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .opacity(statsOpacity)

                Spacer()

                // Restart button
                Button(action: onRestart) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Try Again")
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
                .opacity(buttonOpacity)

                Spacer()
                    .frame(height: 40)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                textOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.8).delay(1.0)) {
                statsOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.8).delay(1.8)) {
                buttonOpacity = 1
            }
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cyan.opacity(0.8))

            Text(value)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.cyan.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
