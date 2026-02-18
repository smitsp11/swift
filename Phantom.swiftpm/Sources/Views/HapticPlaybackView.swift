import SwiftUI

struct HapticPlaybackView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var hapticManager: HapticManager
    @EnvironmentObject private var paintSession: PaintSession

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showInstruction = true
    @State private var activeTexture: PainTexture?

    var body: some View {
        ZStack {
            avatarLayer

            VStack {
                topOverlays
                Spacer()
                bottomControls
            }
            .padding(PhantomTheme.Spacing.md)
        }
        .onAppear {
            hapticManager.prepare()
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showInstruction = false
                }
            }
        }
    }

    // MARK: - 3D Avatar Layer

    private var avatarLayer: some View {
        AvatarARView(
            selectedBrush: .constant(.burning),
            pressure: .constant(0.5),
            paintSession: paintSession,
            isDemoMode: false,
            mode: .hapticPlayback,
            reduceMotion: reduceMotion,
            hapticManager: hapticManager,
            onActiveTextureChanged: { texture in
                withAnimation(.easeInOut(duration: 0.15)) {
                    activeTexture = texture
                }
            }
        )
        .ignoresSafeArea()
    }

    // MARK: - Top Overlays

    private var topOverlays: some View {
        HStack(alignment: .top) {
            if showInstruction {
                instructionBadge
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: PhantomTheme.Spacing.sm) {
                engineStatusBadge

                if let texture = activeTexture {
                    activeTextureBadge(texture)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private var instructionBadge: some View {
        GlassCard {
            HStack(spacing: PhantomTheme.Spacing.sm) {
                Image(systemName: "hand.draw.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                Text("Drag finger across painted areas to feel the pain")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, PhantomTheme.Spacing.sm)
            .padding(.vertical, PhantomTheme.Spacing.sm)
        }
        .accessibilityLabel("Instructions: drag finger across painted areas to feel haptic feedback")
    }

    private var engineStatusBadge: some View {
        GlassCard {
            HStack(spacing: 6) {
                Circle()
                    .fill(hapticManager.isAvailable ? .green : .orange)
                    .frame(width: 8, height: 8)

                Text(hapticManager.isAvailable ? "Haptics Ready" : "Haptics Unavailable")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, PhantomTheme.Spacing.sm)
            .padding(.vertical, 6)
        }
        .accessibilityLabel(hapticManager.isAvailable
                            ? "Haptic engine is ready"
                            : "Haptic engine is unavailable on this device")
    }

    private func activeTextureBadge(_ texture: PainTexture) -> some View {
        GlassCard {
            HStack(spacing: 8) {
                Image(systemName: texture.sfSymbol)
                    .font(.body)
                    .foregroundStyle(texture.color)

                Text(texture.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, PhantomTheme.Spacing.md)
            .padding(.vertical, PhantomTheme.Spacing.sm)
        }
        .accessibilityLabel("Feeling \(texture.displayName) pain texture")
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack {
            Spacer()

            Button {
                hapticManager.stopCurrentPattern()
                appViewModel.advancePhase()
            } label: {
                GlassCard {
                    Label("Next: Report", systemImage: "arrow.right")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, PhantomTheme.Spacing.md)
                        .padding(.vertical, PhantomTheme.Spacing.sm)
                }
            }
            .accessibilityLabel("Continue to report")
            .accessibilityHint("Generates a clinical pain report from the painting session")
        }
    }
}
