import Foundation

struct ReportData {
    let location: String
    let quality: String
    let intensity: String
    let recommendation: String
    let summary: String
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct PainReport {
    @Guide(description: "Comma-separated list of affected body regions")
    var location: String
    @Guide(description: "Clinical description of pain qualities reported by the patient, e.g. burning, electric shock, tingling")
    var quality: String
    @Guide(description: "Overall pain intensity assessment from mild to severe, based on mapped pressure data")
    var intensity: String
    @Guide(description: "Brief clinical recommendation for follow-up care")
    var recommendation: String
    @Guide(description: "One-paragraph clinical summary suitable for medical records")
    var summary: String
}
#endif

@MainActor
final class ReportGenerator: ObservableObject {
    @Published var reportData: ReportData?
    @Published var isLoading = false

    func generate(from session: PaintSession) async {
        isLoading = true
        reportData = nil

        let snapshot = SessionSnapshot(session: session)

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let aiReport = await generateWithAI(snapshot: snapshot) {
                reportData = aiReport
                isLoading = false
                return
            }
        }
        #endif

        try? await Task.sleep(for: .seconds(1.5))
        reportData = generateFallback(from: snapshot)
        isLoading = false
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func generateWithAI(snapshot: SessionSnapshot) async -> ReportData? {
        do {
            let session = LanguageModelSession()
            let prompt = snapshot.buildPrompt()
            let response = try await session.respond(to: prompt, generating: PainReport.self)
            return ReportData(
                location: response.location,
                quality: response.quality,
                intensity: response.intensity,
                recommendation: response.recommendation,
                summary: response.summary
            )
        } catch {
            return nil
        }
    }
    #endif

    private func generateFallback(from snapshot: SessionSnapshot) -> ReportData {
        let regions = snapshot.regions.sorted().joined(separator: ", ")

        var qualityParts: [String] = []
        for (texture, count) in snapshot.textureBreakdown.sorted(by: { $0.value > $1.value }) {
            let descriptor: String
            switch texture {
            case .burning:       descriptor = "deep burning sensation"
            case .electric:      descriptor = "sharp electrical jolts"
            case .pinsAndNeedles: descriptor = "persistent tingling (paresthesia)"
            }
            qualityParts.append("\(descriptor) (\(count) areas)")
        }
        let quality = qualityParts.joined(separator: "; ")

        let intensityLabel: String
        let intensityDetail: String
        switch snapshot.averageIntensity {
        case 0..<0.3:
            intensityLabel = "Mild"
            intensityDetail = "Low-intensity signals across mapped regions suggest early-stage or intermittent neuropathic activity."
        case 0.3..<0.6:
            intensityLabel = "Moderate"
            intensityDetail = "Moderate pressure mapping indicates consistent neuropathic discomfort requiring clinical attention."
        case 0.6..<0.8:
            intensityLabel = "Significant"
            intensityDetail = "High-intensity mapping across multiple regions suggests active neuropathic pain warranting prompt evaluation."
        default:
            intensityLabel = "Severe"
            intensityDetail = "Very high intensity signals across the body map indicate severe neuropathic distress requiring urgent clinical review."
        }

        let regionCount = snapshot.regions.count
        let regionWord = regionCount == 1 ? "1 region" : "\(regionCount) regions"

        let recommendation: String
        if snapshot.regions.count >= 4 {
            recommendation = "Multi-region involvement suggests systemic neuropathic condition. Recommend comprehensive neurological evaluation, nerve conduction studies, and consideration of centralized pain management protocol."
        } else if snapshot.textureBreakdown.count >= 2 {
            recommendation = "Mixed pain modalities present across \(regionWord). Recommend targeted neurological assessment and multimodal pain management approach."
        } else {
            recommendation = "Localized neuropathic symptoms in \(regionWord). Recommend focused clinical examination and nerve function assessment."
        }

        let dominantTexture = snapshot.textureBreakdown.max(by: { $0.value < $1.value })?.key
        let dominantName = dominantTexture?.displayName.lowercased() ?? "neuropathic"

        let summary = "Patient reports \(intensityLabel.lowercased()) neuropathic pain across \(regionWord): \(regions). "
            + "The dominant sensation is \(dominantName), with \(snapshot.totalStrokes) discrete pain points mapped during the session. "
            + "\(intensityDetail) "
            + "This sensory map was generated using tactile input translated to haptic feedback, providing a multi-modal pain assessment beyond traditional numeric scales."

        return ReportData(
            location: regions,
            quality: quality,
            intensity: "\(intensityLabel) (\(Int(snapshot.averageIntensity * 100))%)",
            recommendation: recommendation,
            summary: summary
        )
    }
}

struct SessionSnapshot {
    let regions: Set<String>
    let textureBreakdown: [PainTexture: Int]
    let averageIntensity: Float
    let totalStrokes: Int

    init(session: PaintSession) {
        self.regions = session.affectedRegions
        self.textureBreakdown = session.textureBreakdown
        self.averageIntensity = session.averageIntensity
        self.totalStrokes = session.strokes.count
    }

    func buildPrompt() -> String {
        let regionList = regions.sorted().joined(separator: ", ")
        var textureDesc: [String] = []
        for (texture, count) in textureBreakdown.sorted(by: { $0.value > $1.value }) {
            textureDesc.append("\(texture.displayName): \(count) points")
        }
        let intensity = Int(averageIntensity * 10)

        return """
        Generate a clinical neuropathic pain report. \
        Patient mapped \(totalStrokes) pain points across: \(regionList). \
        Pain types: \(textureDesc.joined(separator: ", ")). \
        Average intensity: \(intensity)/10. \
        Provide location, quality description, intensity assessment, recommendation, and summary.
        """
    }
}
