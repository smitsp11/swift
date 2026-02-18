import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

struct ReportView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var paintSession: PaintSession
    @StateObject private var generator = ReportGenerator()

    @State private var appearAnimated = false

    var body: some View {
        ScrollView {
            VStack(spacing: PhantomTheme.Spacing.lg) {
                header
                    .padding(.top, PhantomTheme.Spacing.xl)

                if generator.isLoading {
                    loadingCard
                        .transition(.opacity)
                } else if let report = generator.reportData {
                    reportCard(report)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                disclosureBadge

                actionButtons
                    .padding(.bottom, PhantomTheme.Spacing.xl)
            }
            .padding(.horizontal, PhantomTheme.Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .task {
            await generator.generate(from: paintSession)
            withAnimation(.easeOut(duration: 0.5)) {
                appearAnimated = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: PhantomTheme.Spacing.sm) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.8))
                .accessibilityHidden(true)

            Text("Clinical Pain Report")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text("\(paintSession.strokes.count) pain points mapped across \(paintSession.affectedRegions.count) regions")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Clinical Pain Report. \(paintSession.strokes.count) pain points mapped across \(paintSession.affectedRegions.count) regions.")
    }

    // MARK: - Loading Shimmer

    private var loadingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PhantomTheme.Spacing.md) {
                ForEach(0..<4, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        ShimmerRect(width: 100, height: 12)
                        ShimmerRect(width: .infinity, height: 14)
                        if index < 3 {
                            ShimmerRect(width: 220, height: 14)
                        }
                    }
                }
            }
            .padding(PhantomTheme.Spacing.lg)
        }
        .accessibilityLabel("Generating clinical report")
    }

    // MARK: - Report Card

    private func reportCard(_ report: ReportData) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PhantomTheme.Spacing.lg) {
                reportSection(
                    icon: "mappin.and.ellipse",
                    title: "Affected Regions",
                    content: report.location
                )

                Divider().opacity(0.2)

                reportSection(
                    icon: "waveform.path",
                    title: "Pain Quality",
                    content: report.quality
                )

                Divider().opacity(0.2)

                reportSection(
                    icon: "gauge.with.dots.needle.33percent",
                    title: "Intensity",
                    content: report.intensity
                )

                Divider().opacity(0.2)

                reportSection(
                    icon: "stethoscope",
                    title: "Recommendation",
                    content: report.recommendation
                )

                Divider().opacity(0.2)

                reportSection(
                    icon: "text.document",
                    title: "Summary",
                    content: report.summary
                )
            }
            .padding(PhantomTheme.Spacing.lg)
        }
    }

    private func reportSection(icon: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 20)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(content)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(content)")
    }

    // MARK: - Disclosure Badge

    private var disclosureBadge: some View {
        GlassCard {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .accessibilityHidden(true)

                Text("Generated entirely on-device. No data leaves this iPad.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, PhantomTheme.Spacing.md)
            .padding(.vertical, PhantomTheme.Spacing.sm)
        }
        .accessibilityLabel("Privacy notice: this report was generated entirely on device. No data leaves this iPad.")
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: PhantomTheme.Spacing.md) {
            Button {
                appViewModel.goToPhase(.onboarding)
            } label: {
                GlassCard {
                    Label("New Session", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, PhantomTheme.Spacing.md)
                        .padding(.vertical, PhantomTheme.Spacing.sm)
                }
            }
            .accessibilityLabel("Start a new session")
            .accessibilityHint("Returns to the onboarding screen to begin again")
        }
    }
}

// MARK: - Shimmer Rectangle

private struct ShimmerRect: View {
    let width: CGFloat
    let height: CGFloat

    @State private var shimmerPhase: CGFloat = 0

    init(width: CGFloat = .infinity, height: CGFloat = 14) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.white.opacity(0.08))
            .frame(maxWidth: width == .infinity ? .infinity : width, minHeight: height, maxHeight: height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.12), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerPhase)
            )
            .clipped()
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    shimmerPhase = 300
                }
            }
    }
}
