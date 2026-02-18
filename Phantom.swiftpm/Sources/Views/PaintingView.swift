import SwiftUI
import RealityKit

struct PaintingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var paintSession: PaintSession

    @State private var showInstruction = true
    @State private var isDemoMode: Bool
    @State private var panelHeight: CGFloat = PaintingView.minPanelHeight
    @GestureState private var activeDrag: CGFloat = 0

    private static let minPanelHeight: CGFloat = 70
    private static let maxPanelHeight: CGFloat = 200

    init(isDemoMode: Bool = false) {
        _isDemoMode = State(initialValue: isDemoMode)
    }

    private var effectiveHeight: CGFloat {
        let h = panelHeight - activeDrag
        return min(Self.maxPanelHeight, max(Self.minPanelHeight, h))
    }

    var body: some View {
        AvatarARView(
            selectedBrush: $appViewModel.selectedBrush,
            pressure: $appViewModel.brushPressure,
            paintSession: paintSession,
            isDemoMode: isDemoMode
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            strokeCountBadge
                .padding(.trailing, PhantomTheme.Spacing.lg)
                .padding(.top, PhantomTheme.Spacing.md)
        }
        .overlay(alignment: .bottom) {
            toolbarPanel
                .padding(.horizontal, PhantomTheme.Spacing.md)
                .padding(.bottom, PhantomTheme.Spacing.sm)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showInstruction = false
                }
            }
        }
    }

    // MARK: - Resizable Bottom Panel

    private var toolbarPanel: some View {
        VStack(spacing: 0) {
            dragHandle

            VStack(spacing: PhantomTheme.Spacing.sm) {
                if showInstruction {
                    instructionOverlay
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                BrushToolbar(
                    selectedBrush: $appViewModel.selectedBrush,
                    pressure: $appViewModel.brushPressure,
                    onDone: { appViewModel.advancePhase() }
                )
            }
            .padding(.horizontal, PhantomTheme.Spacing.sm)
            .padding(.bottom, PhantomTheme.Spacing.sm)
            .frame(maxHeight: max(0, effectiveHeight - 24), alignment: .bottom)
            .clipped()
        }
        .frame(width: min(520, .infinity))
        .background(.ultraThinMaterial)
        .cornerRadius(PhantomTheme.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: PhantomTheme.CornerRadius.card)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(.white.opacity(0.35))
            .frame(width: 40, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($activeDrag) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let proposed = panelHeight - value.translation.height
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            panelHeight = min(Self.maxPanelHeight, max(Self.minPanelHeight, proposed))
                        }
                    }
            )
            .accessibilityLabel("Resize toolbar")
            .accessibilityHint("Drag up to expand, drag down to collapse")
    }

    // MARK: - Subviews

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
        HStack(spacing: PhantomTheme.Spacing.sm) {
            Image(systemName: "pencil.tip")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))

            Text("Paint your pain onto the body")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
