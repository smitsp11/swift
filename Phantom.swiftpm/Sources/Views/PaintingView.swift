import SwiftUI
import RealityKit
import PencilKit

struct PaintingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        VStack(spacing: PhantomTheme.Spacing.lg) {
            Spacer()

            GlassCard {
                VStack(spacing: PhantomTheme.Spacing.md) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("Painting Canvas")
                        .font(.title2)
                        .foregroundStyle(.white)

                    Text("3D avatar and paint engine — Phase 2")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(PhantomTheme.Spacing.xl)
            }

            Spacer()

            Button {
                appViewModel.advancePhase()
            } label: {
                GlassCard {
                    Label("Next: Doctor Mode", systemImage: "arrow.right")
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
