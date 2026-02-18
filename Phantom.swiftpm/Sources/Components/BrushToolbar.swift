import SwiftUI

struct BrushToolbar: View {
    @Binding var selectedBrush: PainTexture
    @Binding var pressure: Float
    var onDone: () -> Void

    @Namespace private var brushSelection

    var body: some View {
        GlassCard {
            HStack(spacing: PhantomTheme.Spacing.md) {
                brushButtons
                divider
                pressureSlider
                divider
                doneButton
            }
            .padding(.horizontal, PhantomTheme.Spacing.sm)
        }
    }

    private var brushButtons: some View {
        HStack(spacing: PhantomTheme.Spacing.sm) {
            ForEach(PainTexture.allCases, id: \.self) { texture in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedBrush = texture
                    }
                } label: {
                    ZStack {
                        if selectedBrush == texture {
                            RoundedRectangle(cornerRadius: PhantomTheme.CornerRadius.button)
                                .fill(texture.color.opacity(0.25))
                                .matchedGeometryEffect(id: "brushBG", in: brushSelection)
                        }

                        VStack(spacing: 4) {
                            Image(systemName: texture.sfSymbol)
                                .font(.title3)
                                .foregroundStyle(selectedBrush == texture ? texture.color : .white.opacity(0.5))

                            Text(texture.displayName)
                                .font(.caption2)
                                .foregroundStyle(selectedBrush == texture ? texture.color : .white.opacity(0.4))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(texture.displayName) brush")
                .accessibilityAddTraits(selectedBrush == texture ? .isSelected : [])
            }
        }
    }

    private var pressureSlider: some View {
        VStack(spacing: 2) {
            Text("Intensity")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))

            Slider(value: $pressure, in: 0.1...1.0)
                .tint(selectedBrush.color)
                .frame(width: 120)
                .accessibilityLabel("Pain intensity")
        }
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Label("Done", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: PhantomTheme.CornerRadius.button)
                        .fill(.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Done painting")
        .accessibilityHint("Moves to doctor mode to feel the painted pain")
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(width: 1, height: 36)
    }
}
