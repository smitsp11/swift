import SwiftUI
import RealityKit
@preconcurrency import ARKit
@preconcurrency import Vision
import Combine

/// Central state manager for the SYNAPSE experience.
/// Owns the brain state, drives phase progression, processes hand input,
/// fires signals, and coordinates between Vision, RealityKit, and the UI.
@Observable
@MainActor
class BrainViewModel {

    // MARK: - Published State

    var brainState = BrainState()
    var handDetected: Bool = false
    var currentPhase: ExperiencePhase = .onboarding
    var elapsedTime: TimeInterval = 0
    var isDemoMode: Bool = false

    // MARK: - Experience Phases

    enum ExperiencePhase: String, CaseIterable {
        case onboarding
        case discovery
        case firstSignals
        case growth
        case climax
        case reflection
    }

    // MARK: - Internal State

    private var velocityTracker = VelocitySmoothing()
    var cancellables = Set<AnyCancellable>()
    private var lastFrameTime: Date = .now
    private var experienceTimer: AnyCancellable?

    // Wave gesture detection state machine
    private var waveHistory: [Float] = []  // X-position samples
    private let waveWindowSize = 10        // ~0.3s at 30fps
    private var lastWaveTime: Date = .distantPast
    private let waveCooldown: TimeInterval = 0.4 // min time between fires

    // Scene references
    var sceneAnchor: AnchorEntity?
    private(set) var arView: ARView?

    // Subsystems
    let audioEngine = SynapseAudioEngine()
    let demoController = DemoModeController()

    // Vision processing
    nonisolated let visionQueue = DispatchQueue(
        label: "com.synapse.vision",
        qos: .userInteractive
    )

    // MARK: - Initialization

    init() {
        demoController.onHandUpdate = { [weak self] position, velocity, isWaving in
            self?.handleDemoInput(position: position, velocity: velocity, isWaving: isWaving)
        }
    }

    // MARK: - Setup

    func setupScene(in arView: ARView) {
        self.arView = arView
        let anchor = SceneBuilder.createSceneAnchor()
        self.sceneAnchor = anchor
        arView.scene.addAnchor(anchor)
        audioEngine.setup()
    }

    // MARK: - Experience Timer

    func startExperience() {
        lastFrameTime = .now
        elapsedTime = 0

        experienceTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.experienceTick()
                }
            }
    }

    func stopExperience() {
        experienceTimer?.cancel()
        experienceTimer = nil
        demoController.stop()
        audioEngine.stop()
    }

    private func experienceTick() {
        elapsedTime += 0.1
        advancePhaseIfNeeded()
    }

    // MARK: - Demo Mode

    func startDemoMode() {
        isDemoMode = true
        startExperience()
        // Delay demo start slightly so onboarding is visible
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            self?.demoController.start()
        }
    }

    private func handleDemoInput(position: SIMD3<Float>, velocity: Float, isWaving: Bool) {
        handDetected = true
        if isWaving {
            fireSignalIfReady(velocity: velocity)
        }
    }

    // MARK: - Vision Processing (called from ARSession delegate)

    nonisolated func processARFrame(_ frame: ARFrame) {
        visionQueue.async { [weak self] in
            self?.runHandDetection(on: frame)
        }
    }

    nonisolated private func runHandDetection(on frame: ARFrame) {
        let handler = VNImageRequestHandler(
            cvPixelBuffer: frame.capturedImage,
            orientation: .right,
            options: [:]
        )
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1

        try? handler.perform([request])

        guard let observation = request.results?.first,
              let wrist = try? observation.recognizedPoint(.wrist),
              let middleTip = try? observation.recognizedPoint(.middleTip) else {
            Task { @MainActor [weak self] in
                self?.handDetected = false
            }
            return
        }

        Task { @MainActor [weak self] in
            self?.handDetected = true
            self?.processHandLandmarks(wrist: wrist, fingertip: middleTip)
        }
    }

    // MARK: - Hand Processing

    private func processHandLandmarks(wrist: VNRecognizedPoint, fingertip: VNRecognizedPoint) {
        guard let arView else { return }

        let now = Date.now
        let dt = Float(now.timeIntervalSince(lastFrameTime))
        lastFrameTime = now

        // Map to 3D scene position
        guard let handPos3D = CoordinateMapping.mapToScene(wrist, in: arView) else { return }

        // Track velocity
        let velocity = velocityTracker.update(position: handPos3D, deltaTime: dt)

        // Wave gesture detection via sliding window
        detectWaveGesture(xPosition: wrist.location.x, velocity: velocity)
    }

    // MARK: - Wave Gesture State Machine

    /// Detects a wave gesture by looking for direction reversals in the X position
    /// over a sliding window. More robust than a simple velocity threshold.
    private func detectWaveGesture(xPosition: CGFloat, velocity: Float) {
        waveHistory.append(Float(xPosition))
        if waveHistory.count > waveWindowSize {
            waveHistory.removeFirst()
        }

        guard waveHistory.count >= waveWindowSize else { return }

        // Check for at least one direction reversal in the window
        var reversals = 0
        for i in 2..<waveHistory.count {
            let prev = waveHistory[i-1] - waveHistory[i-2]
            let curr = waveHistory[i] - waveHistory[i-1]
            if prev * curr < 0 && abs(curr) > 0.002 {
                reversals += 1
            }
        }

        // Need at least one reversal and sufficient velocity
        let timeSinceLastWave = Date.now.timeIntervalSince(lastWaveTime)
        if reversals >= 1 && velocity > 80 && timeSinceLastWave > waveCooldown {
            lastWaveTime = .now
            fireSignalIfReady(velocity: velocity)
        }
    }

    // MARK: - Signal Firing

    func fireSignalIfReady(velocity: Float) {
        guard currentPhase != .onboarding && currentPhase != .reflection else { return }
        guard let pathway = nextFirablePathway() else { return }
        guard let anchor = sceneAnchor else { return }

        let pathwayIndex = brainState.pathways.firstIndex(where: { $0.id == pathway.id })!

        // Apply neuroplasticity growth
        let newStrength = NeuroplasticityEngine.calculateGrowth(
            currentStrength: pathway.strength,
            velocity: velocity
        )

        // Check for myelination milestones (25%, 50%, 75%, 100%)
        let oldMilestone = Int(pathway.strength * 4)
        let newMilestone = Int(newStrength * 4)
        if newMilestone > oldMilestone {
            audioEngine.playMyelinationBloom()
        }

        brainState.pathways[pathwayIndex].strength = newStrength
        brainState.pathways[pathwayIndex].signalCount += 1
        brainState.totalSignalsFired += 1
        brainState.peakMyelination = max(brainState.peakMyelination, newStrength)

        // Update axon visuals
        let srcNeuron = brainState.neurons.first { $0.id == pathway.sourceNeuronID }!
        let dstNeuron = brainState.neurons.first { $0.id == pathway.destinationNeuronID }!

        NeuronFactory.updateAxonVisuals(
            pathway: &brainState.pathways[pathwayIndex],
            sourcePosition: srcNeuron.position,
            destPosition: dstNeuron.position
        )

        // Pulse the source neuron
        if let entity = srcNeuron.entity {
            NeuronFactory.pulseNeuron(entity)
        }

        // Play audio
        audioEngine.playSignalPing(myelinationStrength: newStrength)

        // Fire the visual spark
        SparkFactory.fireSignal(
            from: srcNeuron.position,
            to: dstNeuron.position,
            duration: pathway.signalSpeed,
            pathway: brainState.pathways[pathwayIndex],
            in: anchor,
            cancellables: &cancellables,
            onArrival: { [weak self] in
                Task { @MainActor in
                    // Pulse destination neuron on arrival
                    if let dstEntity = dstNeuron.entity {
                        NeuronFactory.pulseNeuron(dstEntity)
                    }
                    // Cascade: fire downstream pathways automatically
                    self?.cascadeSignal(from: dstNeuron.id, velocity: velocity * 0.8)
                }
            }
        )
    }

    /// When a signal arrives at a neuron, automatically fire signals
    /// along that neuron's downstream pathways (cascade effect).
    private func cascadeSignal(from neuronID: UUID, velocity: Float) {
        guard currentPhase == .climax || currentPhase == .growth else { return }
        guard velocity > 40 else { return } // decay threshold

        let downstreamPathways = brainState.pathways.filter { $0.sourceNeuronID == neuronID }
        for pathway in downstreamPathways {
            guard let anchor = sceneAnchor else { continue }
            let src = brainState.neurons.first { $0.id == pathway.sourceNeuronID }!
            let dst = brainState.neurons.first { $0.id == pathway.destinationNeuronID }!

            // Grow downstream pathways too (at reduced rate)
            if let idx = brainState.pathways.firstIndex(where: { $0.id == pathway.id }) {
                let newStrength = NeuroplasticityEngine.calculateGrowth(
                    currentStrength: pathway.strength,
                    velocity: velocity
                )
                brainState.pathways[idx].strength = newStrength
                brainState.pathways[idx].signalCount += 1

                NeuronFactory.updateAxonVisuals(
                    pathway: &brainState.pathways[idx],
                    sourcePosition: src.position,
                    destPosition: dst.position
                )
            }

            SparkFactory.fireSignal(
                from: src.position,
                to: dst.position,
                duration: pathway.signalSpeed,
                pathway: pathway,
                in: anchor,
                cancellables: &cancellables,
                onArrival: { [weak self] in
                    Task { @MainActor in
                        if let dstEntity = dst.entity {
                            NeuronFactory.pulseNeuron(dstEntity)
                        }
                        self?.cascadeSignal(from: dst.id, velocity: velocity * 0.7)
                    }
                }
            )
        }
    }

    // MARK: - Pathway Selection

    /// Returns the next pathway to fire a signal on, cycling through available pathways.
    /// Prefers pathways with lower myelination (encouraging the user to explore the network).
    private func nextFirablePathway() -> NeuralPathway? {
        guard !brainState.pathways.isEmpty else { return nil }

        // Sort by signal count ascending — fire the least-used pathway first
        // This encourages balanced network growth
        return brainState.pathways.min(by: { $0.signalCount < $1.signalCount })
    }

    // MARK: - Phase Management

    private func advancePhaseIfNeeded() {
        guard let anchor = sceneAnchor else { return }
        let signals = brainState.totalSignalsFired

        switch currentPhase {
        case .onboarding:
            // Transition after brief onboarding period
            if elapsedTime >= 3 {
                currentPhase = .discovery
                SceneBuilder.revealNeurons(
                    in: &brainState,
                    upTo: NetworkLayout.phaseReveal[0],
                    anchor: anchor
                )
            }

        case .discovery:
            // Transition when user fires first signal OR after timeout
            if signals >= 1 || elapsedTime >= 20 {
                currentPhase = .firstSignals
            }

        case .firstSignals:
            // Transition after several signals or timeout — reveal more neurons
            if signals >= NetworkLayout.signalThresholds[2] || elapsedTime >= 60 {
                currentPhase = .growth
                SceneBuilder.revealNeurons(
                    in: &brainState,
                    upTo: NetworkLayout.phaseReveal[1],
                    anchor: anchor
                )
            }

        case .growth:
            // Transition after significant signals or timeout — reveal full network
            if signals >= NetworkLayout.signalThresholds[3] || elapsedTime >= 120 {
                currentPhase = .climax
                SceneBuilder.revealNeurons(
                    in: &brainState,
                    upTo: NetworkLayout.phaseReveal[2],
                    anchor: anchor
                )
            }

        case .climax:
            // Transition to reflection after the climax plays out
            if signals >= NetworkLayout.signalThresholds[4] || elapsedTime >= 170 {
                currentPhase = .reflection
            }

        case .reflection:
            break // Terminal state
        }
    }
}
