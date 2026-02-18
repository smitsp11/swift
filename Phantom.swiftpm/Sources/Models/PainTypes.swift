import simd
import SwiftUI

enum PainTexture: String, CaseIterable, Sendable {
    case burning
    case electric
    case pinsAndNeedles

    var displayName: String {
        switch self {
        case .burning:       return "Burning"
        case .electric:      return "Electric"
        case .pinsAndNeedles: return "Pins & Needles"
        }
    }

    var sfSymbol: String {
        switch self {
        case .burning:       return "flame.fill"
        case .electric:      return "bolt.fill"
        case .pinsAndNeedles: return "wave.3.right"
        }
    }

    var color: Color {
        switch self {
        case .burning:       return Color(red: 1.0, green: 0.35, blue: 0.1)
        case .electric:      return Color(red: 0.3, green: 0.85, blue: 1.0)
        case .pinsAndNeedles: return Color(red: 0.9, green: 0.4, blue: 0.9)
        }
    }
}

struct PaintStroke: Sendable, Identifiable {
    let id = UUID()
    let location: SIMD3<Float>
    let texture: PainTexture
    let pressure: Float
    let bodyRegion: String
}
