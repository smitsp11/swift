import SwiftUI

struct OnboardingView: View {
    var onDemo: () -> Void
    var onBegin: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var titleOpacity: Double = 0
    @State private var visibleCharacters: Int = 0
    @State private var buttonsOpacity: Double = 0

    private let tagline = "Pain is a language without words.\nPhantom is the translator."

    var body: some View {
        VStack(spacing: PhantomTheme.Spacing.xl) {
            Spacer()

            Text("Phantom")
                .font(.system(size: 48, weight: .thin, design: .default))
                .foregroundStyle(.white)
                .opacity(titleOpacity)
                .accessibilityAddTraits(.isHeader)

            Text(displayedTagline)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(minHeight: 52, alignment: .top)
                .accessibilityLabel(tagline)

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
            .opacity(buttonsOpacity)

            Spacer()
                .frame(height: PhantomTheme.Spacing.xxl)
        }
        .padding(PhantomTheme.Spacing.xl)
        .onAppear { startAnimations() }
    }

    private var displayedTagline: String {
        if reduceMotion || visibleCharacters >= tagline.count {
            return tagline
        }
        let index = tagline.index(tagline.startIndex, offsetBy: visibleCharacters)
        return String(tagline[..<index])
    }

    private func startAnimations() {
        if reduceMotion {
            titleOpacity = 1
            visibleCharacters = tagline.count
            buttonsOpacity = 1
            return
        }

        withAnimation(.easeIn(duration: 0.8)) {
            titleOpacity = 1
        }

        let charDelay = 0.04
        let startAfter = 0.9
        for i in 1...tagline.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + startAfter + charDelay * Double(i)) {
                visibleCharacters = i
            }
        }

        let totalTypewriterTime = startAfter + charDelay * Double(tagline.count)
        DispatchQueue.main.asyncAfter(deadline: .now() + totalTypewriterTime + 0.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                buttonsOpacity = 1
            }
        }
    }
}
