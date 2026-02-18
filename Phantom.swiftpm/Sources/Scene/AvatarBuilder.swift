import RealityKit
import UIKit

enum AvatarBuilder {

    static func build() -> Entity {
        let root = Entity()
        root.name = "avatarRoot"

        let glowColor = UIColor(red: 0.35, green: 0.18, blue: 0.65, alpha: 0.9)
        var material = UnlitMaterial(color: glowColor)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.85))

        let parts: [(name: String, mesh: MeshResource, position: SIMD3<Float>)] = [
            ("head",          .generateSphere(radius: 0.10),                                      [0,     0.78, 0]),
            ("neck",          .generateBox(width: 0.05, height: 0.06, depth: 0.05, cornerRadius: 0.02), [0,     0.65, 0]),
            ("upperTorso",    .generateBox(width: 0.30, height: 0.22, depth: 0.14, cornerRadius: 0.05), [0,     0.50, 0]),
            ("lowerTorso",    .generateBox(width: 0.26, height: 0.18, depth: 0.13, cornerRadius: 0.05), [0,     0.32, 0]),
            ("pelvis",        .generateBox(width: 0.24, height: 0.10, depth: 0.12, cornerRadius: 0.04), [0,     0.18, 0]),

            ("leftShoulder",  .generateSphere(radius: 0.045),                                     [-0.19, 0.58, 0]),
            ("rightShoulder", .generateSphere(radius: 0.045),                                     [ 0.19, 0.58, 0]),

            ("leftUpperArm",  .generateBox(width: 0.07, height: 0.20, depth: 0.07, cornerRadius: 0.03), [-0.22, 0.43, 0]),
            ("rightUpperArm", .generateBox(width: 0.07, height: 0.20, depth: 0.07, cornerRadius: 0.03), [ 0.22, 0.43, 0]),
            ("leftForearm",   .generateBox(width: 0.06, height: 0.20, depth: 0.06, cornerRadius: 0.025),[-0.22, 0.23, 0]),
            ("rightForearm",  .generateBox(width: 0.06, height: 0.20, depth: 0.06, cornerRadius: 0.025),[ 0.22, 0.23, 0]),

            ("leftUpperLeg",  .generateBox(width: 0.09, height: 0.26, depth: 0.09, cornerRadius: 0.035),[-0.09, -0.01, 0]),
            ("rightUpperLeg", .generateBox(width: 0.09, height: 0.26, depth: 0.09, cornerRadius: 0.035),[ 0.09, -0.01, 0]),
            ("leftLowerLeg",  .generateBox(width: 0.07, height: 0.26, depth: 0.07, cornerRadius: 0.03), [-0.09, -0.30, 0]),
            ("rightLowerLeg", .generateBox(width: 0.07, height: 0.26, depth: 0.07, cornerRadius: 0.03), [ 0.09, -0.30, 0]),
        ]

        for part in parts {
            let entity = ModelEntity(mesh: part.mesh, materials: [material])
            entity.name = part.name
            entity.position = part.position
            entity.generateCollisionShapes(recursive: false)
            root.addChild(entity)
        }

        return root
    }
}
