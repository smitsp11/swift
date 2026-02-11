import SwiftUI
import RealityKit
@preconcurrency import ARKit

/// UIViewRepresentable wrapping an ARView for the SYNAPSE experience.
/// Provides camera passthrough, delivers AR frames to the Vision pipeline,
/// and hosts the RealityKit scene.
struct ARExperienceView: UIViewRepresentable {
    let viewModel: BrainViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session for world tracking
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []  // We don't need plane detection
        config.isLightEstimationEnabled = false // Save processing
        arView.session.run(config)

        // Set the delegate to receive frame updates
        arView.session.delegate = context.coordinator

        // Setup the RealityKit scene
        viewModel.setupScene(in: arView)

        // Subtle dark tint on camera feed so 3D elements pop
        arView.environment.background = .cameraFeed(exposureCompensation: -0.5)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // No dynamic SwiftUI-driven updates needed;
        // all mutations go through BrainViewModel
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - ARSession Delegate

    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: BrainViewModel
        private var frameSkipCounter = 0

        init(viewModel: BrainViewModel) {
            self.viewModel = viewModel
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Process every other frame to save CPU (30fps instead of 60fps for Vision)
            frameSkipCounter += 1
            guard frameSkipCounter % 2 == 0 else { return }

            viewModel.processARFrame(frame)
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            print("ARSession error: \(error.localizedDescription)")
            // In a real scenario we'd show an error overlay here
        }

        func sessionWasInterrupted(_ session: ARSession) {
            print("ARSession interrupted")
        }

        func sessionInterruptionEnded(_ session: ARSession) {
            print("ARSession interruption ended")
        }
    }
}
