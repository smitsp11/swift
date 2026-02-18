import RealityKit
import UIKit

enum PaintMarkEntity {

    private static let burningColor   = UIColor(red: 1.0, green: 0.35, blue: 0.1, alpha: 1.0)
    private static let electricColor  = UIColor(red: 0.3, green: 0.85, blue: 1.0, alpha: 1.0)
    private static let needlesColor   = UIColor(red: 0.9, green: 0.4,  blue: 0.9, alpha: 1.0)

    static func create(
        for texture: PainTexture,
        at position: SIMD3<Float>,
        pressure: Float
    ) -> ModelEntity {
        let baseRadius: Float = 0.012
        let radius = baseRadius * (0.6 + pressure * 0.6)
        let mesh = MeshResource.generateSphere(radius: radius)

        let color: UIColor
        switch texture {
        case .burning:      color = burningColor
        case .electric:     color = electricColor
        case .pinsAndNeedles: color = needlesColor
        }

        var material = UnlitMaterial(color: color)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.9))

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position
        entity.name = "paintMark_\(texture.rawValue)"
        return entity
    }

    static func createGlowHalo(
        for texture: PainTexture,
        at position: SIMD3<Float>,
        pressure: Float
    ) -> ModelEntity {
        let haloRadius: Float = 0.022 * (0.6 + pressure * 0.6)
        let mesh = MeshResource.generateSphere(radius: haloRadius)

        let color: UIColor
        switch texture {
        case .burning:      color = burningColor.withAlphaComponent(0.3)
        case .electric:     color = electricColor.withAlphaComponent(0.25)
        case .pinsAndNeedles: color = needlesColor.withAlphaComponent(0.3)
        }

        var material = UnlitMaterial(color: color)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.35))

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position
        entity.name = "paintHalo_\(texture.rawValue)"
        return entity
    }
}
