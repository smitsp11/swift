import SwiftUI
import RealityKit

struct PaintingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var paintSession: PaintSession

    @State private var showInstruction = true
    @State private var isDemoMode: Bool

    init(isDemoMode: Bool = false) {
        _isDemoMode = State(initialValue: isDemoMode)
    }

    var body: some View {
        ZStack {
            AvatarARView(
                selectedBrush: $appViewModel.selectedBrush,
                pressure: $appViewModel.brushPressure,
                paintSession: paintSession,
                isDemoMode: isDemoMode
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    strokeCountBadge
                        .padding(.trailing, PhantomTheme.Spacing.lg)
                        .padding(.top, PhantomTheme.Spacing.md)
                }

                Spacer()

                if showInstruction {
                    instructionOverlay
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                BrushToolbar(
                    selectedBrush: $appViewModel.selectedBrush,
                    pressure: $appViewModel.brushPressure,
                    onDone: { appViewModel.advancePhase() }
                )
                .padding(.horizontal, PhantomTheme.Spacing.xl)
                .padding(.bottom, PhantomTheme.Spacing.lg)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showInstruction = false
                }
            }
        }
    }

    private var strokeCountBadge: some View {
        GlassCard {
            HStack(spacing: 6) {
                Image(systemName: "hand.draw.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(paintSession.strokes.count)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel("\(paintSession.strokes.count) strokes painted")
    }

    private var instructionOverlay: some View {
        GlassCard {
            HStack(spacing: PhantomTheme.Spacing.sm) {
                Image(systemName: "pencil.tip")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))

                Text("Paint your pain onto the body")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.bottom, PhantomTheme.Spacing.sm)
    }
}
