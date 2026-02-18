import SwiftUI

struct HapticPlaybackView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var hapticManager: HapticManager

    var body: some View {
        VStack(spacing: PhantomTheme.Spacing.lg) {
            Spacer()

            GlassCard {
                VStack(spacing: PhantomTheme.Spacing.md) {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("Doctor Mode — Feel Mode")
                        .font(.title2)
                        .foregroundStyle(.white)

                    Text("Haptic playback engine — Phase 3")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))

                    Text(hapticManager.isAvailable
                         ? "Haptic engine: ready"
                         : "Haptic engine: unavailable (simulator)")
                        .font(.caption)
                        .foregroundStyle(hapticManager.isAvailable
                                         ? .green.opacity(0.8)
                                         : .orange.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(PhantomTheme.Spacing.xl)
            }

            Spacer()

            Button {
                appViewModel.advancePhase()
            } label: {
                GlassCard {
                    Label("Next: Report", systemImage: "arrow.right")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }

            Spacer()
                .frame(height: PhantomTheme.Spacing.lg)
        }
        .padding(PhantomTheme.Spacing.xl)
    }
}
