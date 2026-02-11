import AVFoundation

/// Procedural audio synthesis engine for SYNAPSE.
/// Generates all sounds at runtime — no audio files needed.
/// Marked @unchecked Sendable because the audio render callback accesses
/// properties from the real-time audio thread (locks are not suitable here).
class SynapseAudioEngine: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?

    // Tone state (accessed from audio render thread)
    private var currentFrequency: Float = 0
    private var targetAmplitude: Float = 0
    private var amplitude: Float = 0
    private var phase: Float = 0

    private let sampleRate: Double = 44100
    private var isRunning = false

    // MARK: - Setup

    func setup() {
        guard !isRunning else { return }

        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ) else { return }

        let sr = sampleRate
        sourceNode = AVAudioSourceNode(format: format) {
            [weak self] _, _, frameCount, bufferList in
            guard let self else { return noErr }

            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let buffer = ablPointer.first,
                  let mData = buffer.mData else { return noErr }
            let ptr = mData.assumingMemoryBound(to: Float.self)

            for i in 0..<Int(frameCount) {
                // Smooth amplitude envelope
                self.amplitude += (self.targetAmplitude - self.amplitude) * 0.001

                ptr[i] = sin(self.phase * 2.0 * .pi) * self.amplitude
                self.phase += self.currentFrequency / Float(sr)
                if self.phase > 1.0 { self.phase -= 1.0 }
            }
            return noErr
        }

        guard let sourceNode else { return }
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)

        // Lower the main volume so pings are subtle
        engine.mainMixerNode.outputVolume = 0.5

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            isRunning = true
        } catch {
            print("SynapseAudioEngine setup failed: \(error)")
        }
    }

    // MARK: - Sound Events

    /// Plays a short ping whose pitch rises with myelination level.
    /// Frequency: 220 Hz (unmyelinated) → 660 Hz (fully myelinated).
    func playSignalPing(myelinationStrength: Float) {
        let freq = 220 + 440 * myelinationStrength
        currentFrequency = freq
        targetAmplitude = 0.3

        // Decay envelope: fade out over 0.25s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.targetAmplitude = 0.1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.targetAmplitude = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.currentFrequency = 0
        }
    }

    /// Plays a low resonant bloom when a myelination milestone is reached.
    func playMyelinationBloom() {
        let previousFreq = currentFrequency
        let previousAmp = targetAmplitude

        currentFrequency = 80
        targetAmplitude = 0.15

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.currentFrequency = previousFreq
            self?.targetAmplitude = previousAmp
        }
    }

    // MARK: - Teardown

    func stop() {
        targetAmplitude = 0
        currentFrequency = 0
        engine.stop()
        isRunning = false
    }
}
