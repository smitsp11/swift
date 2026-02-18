import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

struct ReportView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        VStack(spacing: PhantomTheme.Spacing.lg) {
            Spacer()

            GlassCard {
                VStack(spacing: PhantomTheme.Spacing.md) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("Clinical Report")
                        .font(.title2)
                        .foregroundStyle(.white)

                    Text("AI-generated report — Phase 4")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(PhantomTheme.Spacing.xl)
            }

            Spacer()

            Button {
                appViewModel.goToPhase(.onboarding)
            } label: {
                GlassCard {
                    Label("Back to Start", systemImage: "arrow.counterclockwise")
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
