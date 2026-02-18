import simd

enum PainTexture: String, CaseIterable, Sendable {
    case burning
    case electric
    case pinsAndNeedles
}

struct PaintStroke: Sendable {
    let location: SIMD3<Float>
    let texture: PainTexture
    let pressure: Float
    let bodyRegion: String
}
