import simd

enum BodyRegionMapper {

    private static let entityNameMap: [String: String] = [
        "head": "Head",
        "neck": "Neck",
        "upperTorso": "Upper Torso",
        "lowerTorso": "Lower Torso",
        "pelvis": "Pelvis",
        "leftShoulder": "Left Shoulder",
        "rightShoulder": "Right Shoulder",
        "leftUpperArm": "Left Upper Arm",
        "rightUpperArm": "Right Upper Arm",
        "leftForearm": "Left Forearm",
        "rightForearm": "Right Forearm",
        "leftUpperLeg": "Left Upper Leg",
        "rightUpperLeg": "Right Upper Leg",
        "leftLowerLeg": "Left Lower Leg",
        "rightLowerLeg": "Right Lower Leg",
    ]

    static func region(forEntityNamed name: String) -> String {
        entityNameMap[name] ?? regionFromCoordinate(.zero)
    }

    static func regionFromCoordinate(_ position: SIMD3<Float>) -> String {
        let y = position.y
        let x = position.x
        let side = x < -0.05 ? "Left " : (x > 0.05 ? "Right " : "")

        if y > 0.65 { return "Head" }
        if y > 0.55 { return "\(side)Shoulder".trimmingCharacters(in: .whitespaces) }
        if y > 0.35 { return "Upper Torso" }
        if y > 0.20 { return "Lower Torso" }
        if y > 0.10 { return "Pelvis" }
        if y > -0.10 { return "\(side)Hip".trimmingCharacters(in: .whitespaces) }
        if y > -0.30 { return "\(side)Upper Leg".trimmingCharacters(in: .whitespaces) }
        return "\(side)Lower Leg".trimmingCharacters(in: .whitespaces)
    }
}
