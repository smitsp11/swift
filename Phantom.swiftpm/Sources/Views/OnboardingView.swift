import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        VStack(spacing: PhantomTheme.Spacing.xl) {
            Spacer()

            Text("Phantom")
                .font(.system(size: 48, weight: .thin, design: .default))
                .foregroundStyle(.white)

            Text("Pain is a language without words.\nPhantom is the translator.")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()

            HStack(spacing: PhantomTheme.Spacing.md) {
                Button {
                    appViewModel.advancePhase()
                } label: {
                    GlassCard {
                        Label("Begin", systemImage: "hand.draw")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(minWidth: 140)
                    }
                }

                Button {
                    appViewModel.advancePhase()
                } label: {
                    GlassCard {
                        Label("Demo Mode", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(minWidth: 140)
                    }
                }
            }

            Spacer()
                .frame(height: PhantomTheme.Spacing.xxl)
        }
        .padding(PhantomTheme.Spacing.xl)
    }
}
