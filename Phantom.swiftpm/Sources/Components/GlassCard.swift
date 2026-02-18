import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(PhantomTheme.Spacing.md)
            .background(.ultraThinMaterial)
            .cornerRadius(PhantomTheme.CornerRadius.card)
            .shadow(color: .white.opacity(0.05), radius: 10, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: PhantomTheme.CornerRadius.card)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}
