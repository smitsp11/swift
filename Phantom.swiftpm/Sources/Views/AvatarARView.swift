import SwiftUI
import RealityKit

struct AvatarARView: UIViewRepresentable {
    @Binding var selectedBrush: PainTexture
    @Binding var pressure: Float
    var paintSession: PaintSession
    var isDemoMode: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.environment.background = .color(
            UIColor(red: 0.04, green: 0.0, blue: 0.06, alpha: 1.0)
        )

        let coordinator = context.coordinator
        coordinator.arView = arView
        coordinator.setupScene()

        let overlay = TouchOverlay(frame: arView.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = .clear
        overlay.isMultipleTouchEnabled = true
        overlay.coordinator = coordinator
        arView.addSubview(overlay)
        coordinator.overlay = overlay

        let hoverGesture = UIHoverGestureRecognizer(
            target: coordinator,
            action: #selector(Coordinator.handleHover(_:))
        )
        overlay.addGestureRecognizer(hoverGesture)

        if isDemoMode {
            coordinator.loadDemoMarks()
        }

        coordinator.startAnimationTimer()

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        context.coordinator.selectedBrush = selectedBrush
        context.coordinator.sliderPressure = pressure
    }

    static func dismantleUIView(_ arView: ARView, coordinator: Coordinator) {
        coordinator.stopAnimationTimer()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(paintSession: paintSession)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        weak var arView: ARView?
        weak var overlay: TouchOverlay?
        var paintSession: PaintSession
        var selectedBrush: PainTexture = .burning
        var sliderPressure: Float = 0.5
        var avatarRoot: Entity?

        private var animationTimer: Timer?
        private var paintMarkInfos: [PaintMarkInfo] = []
        private var hoverPreviewEntity: ModelEntity?

        private var rotationAnchorEntity: Entity?
        private var initialRotationAngle: Float = 0
        private var currentYRotation: Float = 0

        private static let maxPaintMarks = 200
        private static let minStrokeDistance: Float = 0.015

        struct PaintMarkInfo {
            let entity: Entity
            let haloEntity: Entity?
            let texture: PainTexture
            let basePosition: SIMD3<Float>
            let baseScale: SIMD3<Float>
        }

        init(paintSession: PaintSession) {
            self.paintSession = paintSession
        }

        // MARK: - Scene Setup

        func setupScene() {
            guard let arView = arView else { return }

            let anchor = AnchorEntity(world: .zero)

            let avatar = AvatarBuilder.build()
            anchor.addChild(avatar)
            self.avatarRoot = avatar
            self.rotationAnchorEntity = anchor

            arView.scene.addAnchor(anchor)

            let cameraAnchor = AnchorEntity(world: .zero)
            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 50
            camera.position = [0, 0.30, 2.2]
            camera.look(at: [0, 0.30, 0], from: camera.position, relativeTo: nil)
            cameraAnchor.addChild(camera)

            let light = PointLight()
            light.light.intensity = 500
            light.light.color = UIColor(red: 0.6, green: 0.5, blue: 1.0, alpha: 1.0)
            light.position = [0, 1.0, 2.0]
            cameraAnchor.addChild(light)

            let fillLight = PointLight()
            fillLight.light.intensity = 200
            fillLight.light.color = UIColor(red: 0.4, green: 0.3, blue: 0.8, alpha: 1.0)
            fillLight.position = [-1.0, 0.3, 1.5]
            cameraAnchor.addChild(fillLight)

            arView.scene.addAnchor(cameraAnchor)
        }

        // MARK: - Touch Handling

        func handleTouchBegan(_ touch: UITouch, in view: UIView) {
            let point = touch.location(in: view)
            let force = touchPressure(touch)
            placePaintMark(at: point, pressure: force)
        }

        func handleTouchMoved(_ touch: UITouch, in view: UIView) {
            let point = touch.location(in: view)
            let force = touchPressure(touch)
            placePaintMark(at: point, pressure: force)
        }

        func handleRotation(translation: CGPoint) {
            guard let anchor = rotationAnchorEntity else { return }
            let sensitivity: Float = 0.008
            let angle = initialRotationAngle + Float(translation.x) * sensitivity
            currentYRotation = angle
            anchor.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
        }

        func beginRotation() {
            initialRotationAngle = currentYRotation
        }

        // MARK: - Paint Mark Placement

        private func placePaintMark(at screenPoint: CGPoint, pressure: Float) {
            guard let arView = arView,
                  let avatarRoot = avatarRoot,
                  paintMarkInfos.count < Self.maxPaintMarks else { return }

            guard let ray = arView.ray(through: screenPoint) else { return }

            let results = arView.scene.raycast(
                origin: ray.origin,
                direction: ray.direction,
                length: 10,
                query: .nearest
            )

            guard let hit = results.first else { return }

            let hitEntity = hit.entity
            let worldPos = hit.position
            let localPos = avatarRoot.convert(position: worldPos, from: nil)

            if let lastInfo = paintMarkInfos.last {
                let dist = simd_distance(localPos, lastInfo.basePosition)
                if dist < Self.minStrokeDistance { return }
            }

            let entityName = hitEntity.name
            let region: String
            if entityName.hasPrefix("paintMark") || entityName.hasPrefix("paintHalo") {
                region = BodyRegionMapper.regionFromCoordinate(localPos)
            } else {
                let mapped = BodyRegionMapper.region(forEntityNamed: entityName)
                region = mapped == BodyRegionMapper.regionFromCoordinate(.zero)
                    ? BodyRegionMapper.regionFromCoordinate(localPos)
                    : mapped
            }

            let offsetPos = localPos + hit.normal * 0.005

            let mark = PaintMarkEntity.create(
                for: selectedBrush,
                at: offsetPos,
                pressure: pressure
            )
            avatarRoot.addChild(mark)

            let halo = PaintMarkEntity.createGlowHalo(
                for: selectedBrush,
                at: offsetPos,
                pressure: pressure
            )
            avatarRoot.addChild(halo)

            paintMarkInfos.append(PaintMarkInfo(
                entity: mark,
                haloEntity: halo,
                texture: selectedBrush,
                basePosition: offsetPos,
                baseScale: mark.scale
            ))

            let stroke = PaintStroke(
                location: localPos,
                texture: selectedBrush,
                pressure: pressure,
                bodyRegion: region
            )
            Task { @MainActor in
                paintSession.addStroke(stroke)
            }
        }

        private func touchPressure(_ touch: UITouch) -> Float {
            if touch.type == .pencil || touch.type == .direct {
                let maxForce = touch.maximumPossibleForce
                if maxForce > 0 {
                    return max(0.1, min(1.0, Float(touch.force / maxForce)))
                }
            }
            return sliderPressure
        }

        // MARK: - Demo Mode
        @MainActor
        func loadDemoMarks() {
            guard let avatarRoot = avatarRoot else { return }

            for stroke in paintSession.strokes {
                let mark = PaintMarkEntity.create(
                    for: stroke.texture,
                    at: stroke.location,
                    pressure: stroke.pressure
                )
                avatarRoot.addChild(mark)

                let halo = PaintMarkEntity.createGlowHalo(
                    for: stroke.texture,
                    at: stroke.location,
                    pressure: stroke.pressure
                )
                avatarRoot.addChild(halo)

                paintMarkInfos.append(PaintMarkInfo(
                    entity: mark,
                    haloEntity: halo,
                    texture: stroke.texture,
                    basePosition: stroke.location,
                    baseScale: mark.scale
                ))
            }
        }

        // MARK: - Animation Timer

        func startAnimationTimer() {
            animationTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0 / 30.0,
                repeats: true
            ) { [weak self] _ in
                self?.updateAnimations()
            }
        }

        func stopAnimationTimer() {
            animationTimer?.invalidate()
            animationTimer = nil
        }

        private func updateAnimations() {
            let time = CACurrentMediaTime()

            for info in paintMarkInfos {
                switch info.texture {
                case .burning:
                    let pulse = Float(sin(time * 2.5)) * 0.25 + 1.0
                    info.entity.scale = info.baseScale * pulse
                    info.haloEntity?.scale = info.baseScale * (pulse * 1.3)

                case .electric:
                    let flicker = Float.random(in: 0...1.0)
                    info.entity.isEnabled = flicker > 0.2
                    info.haloEntity?.isEnabled = flicker > 0.35

                case .pinsAndNeedles:
                    let jitter = SIMD3<Float>(
                        Float.random(in: -0.002...0.002),
                        Float.random(in: -0.002...0.002),
                        Float.random(in: -0.002...0.002)
                    )
                    info.entity.position = info.basePosition + jitter
                }
            }
        }

        // MARK: - Hover Preview

        @objc func handleHover(_ gesture: UIHoverGestureRecognizer) {
            guard let arView = arView, let avatarRoot = avatarRoot else { return }

            switch gesture.state {
            case .began, .changed:
                let point = gesture.location(in: gesture.view)
                guard let ray = arView.ray(through: point) else {
                    removeHoverPreview()
                    return
                }

                let results = arView.scene.raycast(
                    origin: ray.origin,
                    direction: ray.direction,
                    length: 10,
                    query: .nearest
                )

                if let hit = results.first {
                    let localPos = avatarRoot.convert(position: hit.position, from: nil)
                    let offsetPos = localPos + hit.normal * 0.008
                    showHoverPreview(at: offsetPos)
                } else {
                    removeHoverPreview()
                }

            case .ended, .cancelled:
                removeHoverPreview()

            default:
                break
            }
        }

        private func showHoverPreview(at position: SIMD3<Float>) {
            if hoverPreviewEntity == nil {
                let mesh = MeshResource.generateSphere(radius: 0.018)
                let color: UIColor
                switch selectedBrush {
                case .burning:      color = UIColor(red: 1.0, green: 0.35, blue: 0.1, alpha: 0.4)
                case .electric:     color = UIColor(red: 0.3, green: 0.85, blue: 1.0, alpha: 0.35)
                case .pinsAndNeedles: color = UIColor(red: 0.9, green: 0.4, blue: 0.9, alpha: 0.4)
                }
                var material = UnlitMaterial(color: color)
                material.blending = .transparent(opacity: .init(floatLiteral: 0.4))
                let entity = ModelEntity(mesh: mesh, materials: [material])
                entity.name = "hoverPreview"
                avatarRoot?.addChild(entity)
                hoverPreviewEntity = entity
            }
            hoverPreviewEntity?.position = position
        }

        private func removeHoverPreview() {
            hoverPreviewEntity?.removeFromParent()
            hoverPreviewEntity = nil
        }
    }
}

// MARK: - Touch Overlay

class TouchOverlay: UIView {
    weak var coordinator: AvatarARView.Coordinator?
    private var activeTouches: Set<UITouch> = []
    private var rotationStartMidpoint: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouches.formUnion(touches)

        if activeTouches.count >= 2 {
            coordinator?.beginRotation()
            rotationStartMidpoint = midpoint(of: activeTouches)
            return
        }

        for touch in touches {
            coordinator?.handleTouchBegan(touch, in: self)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if activeTouches.count >= 2 {
            guard let start = rotationStartMidpoint else { return }
            let current = midpoint(of: activeTouches)
            let translation = CGPoint(x: current.x - start.x, y: current.y - start.y)
            coordinator?.handleRotation(translation: translation)
            return
        }

        for touch in touches {
            coordinator?.handleTouchMoved(touch, in: self)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouches.subtract(touches)
        if activeTouches.count < 2 {
            rotationStartMidpoint = nil
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeTouches.subtract(touches)
        if activeTouches.count < 2 {
            rotationStartMidpoint = nil
        }
    }

    private func midpoint(of touches: Set<UITouch>) -> CGPoint {
        let points = touches.map { $0.location(in: self) }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
}
