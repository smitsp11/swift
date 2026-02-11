@preconcurrency import ARKit
@preconcurrency import Vision
import RealityKit

/// Converts Vision framework 2D normalized coordinates into RealityKit 3D scene positions.
@MainActor
enum CoordinateMapping {

    /// The Z-depth (in meters) of the virtual plane where neurons live.
    static let neuronPlaneZ: Float = -0.30

    /// Maps a Vision hand landmark to a 3D position in the AR scene.
    ///
    /// Vision coordinates: origin bottom-left, Y-up, normalized 0–1.
    /// ARView screen coordinates: origin top-left, Y-down.
    ///
    /// Strategy: project the 2D screen point onto a virtual plane at a fixed depth
    /// in front of the camera. Uses ARKit raycast first, falling back to manual projection.
    static func mapToScene(
        _ point: VNRecognizedPoint,
        in arView: ARView
    ) -> SIMD3<Float>? {
        guard point.confidence > 0.3 else { return nil }

        let screenX = point.location.x * CGFloat(arView.bounds.width)
        let screenY = (1 - point.location.y) * CGFloat(arView.bounds.height)
        let screenPoint = CGPoint(x: screenX, y: screenY)

        // Try ARKit raycast for real-world depth
        let results = arView.raycast(
            from: screenPoint,
            allowing: .estimatedPlane,
            alignment: .any
        )
        if let first = results.first {
            let col = first.worldTransform.columns.3
            return SIMD3<Float>(col.x, col.y, col.z)
        }

        // Fallback: project onto virtual plane at fixed depth in front of camera
        return projectOntoVirtualPlane(screenPoint: screenPoint, in: arView)
    }

    /// Projects a screen point onto a virtual plane at `neuronPlaneZ` meters
    /// in front of the camera.
    static func projectOntoVirtualPlane(
        screenPoint: CGPoint,
        in arView: ARView
    ) -> SIMD3<Float> {
        let camera = arView.cameraTransform
        let forward = -SIMD3<Float>(
            camera.matrix.columns.2.x,
            camera.matrix.columns.2.y,
            camera.matrix.columns.2.z
        )

        // Compute a rough offset from screen center
        let viewW = Float(arView.bounds.width)
        let viewH = Float(arView.bounds.height)
        let ndcX = (Float(screenPoint.x) / viewW) * 2.0 - 1.0
        let ndcY = -((Float(screenPoint.y) / viewH) * 2.0 - 1.0)

        let right = SIMD3<Float>(
            camera.matrix.columns.0.x,
            camera.matrix.columns.0.y,
            camera.matrix.columns.0.z
        )
        let up = SIMD3<Float>(
            camera.matrix.columns.1.x,
            camera.matrix.columns.1.y,
            camera.matrix.columns.1.z
        )

        let depth = abs(neuronPlaneZ)
        let spread: Float = depth * 0.5 // controls how much screen position affects 3D position

        return camera.translation
             + forward * depth
             + right * ndcX * spread
             + up * ndcY * spread
    }
}
