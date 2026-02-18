import SwiftUI

struct OnboardingView: View {
    var onDemo: () -> Void
    var onBegin: () -> Void

    var body: some View {
        VStack(spacing: PhantomTheme.Spacing.xl) {
            Spacer()

            Text("Phantom")
                .font(.system(size: 48, weight: .thin, design: .default))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            Text("Pain is a language without words.\nPhantom is the translator.")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()

            HStack(spacing: PhantomTheme.Spacing.md) {
                Button(action: onBegin) {
                    GlassCard {
                        Label("Begin", systemImage: "hand.draw")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(minWidth: 140)
                    }
                }
                .accessibilityLabel("Begin painting")
                .accessibilityHint("Start with a blank canvas to paint your pain")

                Button(action: onDemo) {
                    GlassCard {
                        Label("Demo Mode", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(minWidth: 140)
                    }
                }
                .accessibilityLabel("Demo mode")
                .accessibilityHint("Load a prebuilt pain session to explore the experience")
            }

            Spacer()
                .frame(height: PhantomTheme.Spacing.xxl)
        }
        .padding(PhantomTheme.Spacing.xl)
    }
}
