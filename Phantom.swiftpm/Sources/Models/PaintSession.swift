import SwiftUI
import simd

@MainActor
class PaintSession: ObservableObject {
    @Published var strokes: [PaintStroke] = []

    var affectedRegions: Set<String> {
        Set(strokes.map(\.bodyRegion))
    }

    var textureBreakdown: [PainTexture: Int] {
        Dictionary(grouping: strokes, by: \.texture).mapValues(\.count)
    }

    var averageIntensity: Float {
        guard !strokes.isEmpty else { return 0 }
        return strokes.map(\.pressure).reduce(0, +) / Float(strokes.count)
    }

    func nearestStroke(to position: SIMD3<Float>, threshold: Float = 0.06) -> PaintStroke? {
        var best: PaintStroke?
        var bestDist: Float = threshold
        for stroke in strokes {
            let d = simd_distance(position, stroke.location)
            if d < bestDist {
                bestDist = d
                best = stroke
            }
        }
        return best
    }

    func addStroke(_ stroke: PaintStroke) {
        strokes.append(stroke)
    }

    func clear() {
        strokes.removeAll()
    }

    func loadDemo() {
        clear()
        strokes = [
            PaintStroke(location: [0, 0.75, 0.10], texture: .burning, pressure: 0.8, bodyRegion: "Head"),
            PaintStroke(location: [0.03, 0.73, 0.09], texture: .burning, pressure: 0.7, bodyRegion: "Head"),
            PaintStroke(location: [-0.02, 0.76, 0.10], texture: .burning, pressure: 0.65, bodyRegion: "Head"),

            PaintStroke(location: [-0.22, 0.45, 0.05], texture: .electric, pressure: 0.9, bodyRegion: "Left Upper Arm"),
            PaintStroke(location: [-0.22, 0.40, 0.05], texture: .electric, pressure: 0.85, bodyRegion: "Left Upper Arm"),
            PaintStroke(location: [-0.22, 0.35, 0.04], texture: .electric, pressure: 0.8, bodyRegion: "Left Upper Arm"),
            PaintStroke(location: [-0.22, 0.30, 0.04], texture: .electric, pressure: 0.75, bodyRegion: "Left Forearm"),
            PaintStroke(location: [-0.22, 0.25, 0.04], texture: .electric, pressure: 0.7, bodyRegion: "Left Forearm"),

            PaintStroke(location: [0, 0.50, 0.08], texture: .pinsAndNeedles, pressure: 0.5, bodyRegion: "Upper Torso"),
            PaintStroke(location: [0.05, 0.48, 0.08], texture: .pinsAndNeedles, pressure: 0.55, bodyRegion: "Upper Torso"),
            PaintStroke(location: [-0.05, 0.46, 0.07], texture: .pinsAndNeedles, pressure: 0.5, bodyRegion: "Upper Torso"),
            PaintStroke(location: [0, 0.42, 0.07], texture: .pinsAndNeedles, pressure: 0.6, bodyRegion: "Upper Torso"),
            PaintStroke(location: [0.03, 0.35, 0.07], texture: .pinsAndNeedles, pressure: 0.5, bodyRegion: "Lower Torso"),

            PaintStroke(location: [0.10, -0.10, 0.05], texture: .burning, pressure: 0.9, bodyRegion: "Right Upper Leg"),
            PaintStroke(location: [0.10, -0.15, 0.05], texture: .burning, pressure: 0.85, bodyRegion: "Right Upper Leg"),
            PaintStroke(location: [0.10, -0.20, 0.05], texture: .burning, pressure: 0.8, bodyRegion: "Right Upper Leg"),
            PaintStroke(location: [0.10, -0.25, 0.04], texture: .burning, pressure: 0.75, bodyRegion: "Right Upper Leg"),

            PaintStroke(location: [0.10, -0.38, 0.04], texture: .electric, pressure: 0.6, bodyRegion: "Right Lower Leg"),
            PaintStroke(location: [0.10, -0.42, 0.04], texture: .electric, pressure: 0.65, bodyRegion: "Right Lower Leg"),
            PaintStroke(location: [0.10, -0.46, 0.04], texture: .electric, pressure: 0.7, bodyRegion: "Right Lower Leg"),

            PaintStroke(location: [0.22, 0.45, 0.05], texture: .pinsAndNeedles, pressure: 0.4, bodyRegion: "Right Upper Arm"),
            PaintStroke(location: [0.22, 0.40, 0.05], texture: .pinsAndNeedles, pressure: 0.45, bodyRegion: "Right Upper Arm"),

            PaintStroke(location: [0, 0.30, 0.07], texture: .burning, pressure: 0.6, bodyRegion: "Lower Torso"),
            PaintStroke(location: [-0.04, 0.28, 0.07], texture: .burning, pressure: 0.55, bodyRegion: "Lower Torso"),

            PaintStroke(location: [-0.10, -0.10, 0.05], texture: .pinsAndNeedles, pressure: 0.5, bodyRegion: "Left Upper Leg"),
            PaintStroke(location: [-0.10, -0.15, 0.05], texture: .pinsAndNeedles, pressure: 0.55, bodyRegion: "Left Upper Leg"),
            PaintStroke(location: [-0.10, -0.20, 0.04], texture: .pinsAndNeedles, pressure: 0.5, bodyRegion: "Left Upper Leg"),
        ]
    }
}
