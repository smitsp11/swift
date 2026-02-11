import RealityKit
import Foundation

/// Assembles the 3D neural network scene from the predefined NetworkLayout.
/// Handles progressive reveal of neurons as phases advance.
enum SceneBuilder {

    /// Creates the initial scene anchor entity that will hold all neurons and axons.
    static func createSceneAnchor() -> AnchorEntity {
        let anchor = AnchorEntity(world: .zero)
        anchor.name = "SynapseNetwork"
        return anchor
    }

    /// Reveals neurons up to `count` from the NetworkLayout, creating entities
    /// for any newly revealed neurons and their connecting axons.
    ///
    /// - Parameters:
    ///   - state: The current brain state (modified in place).
    ///   - count: Total number of neurons that should be visible after this call.
    ///   - anchor: The scene anchor to add new entities to.
    @MainActor
    static func revealNeurons(
        in state: inout BrainState,
        upTo count: Int,
        anchor: Entity
    ) {
        let targetCount = min(count, NetworkLayout.nodes.count)
        let currentCount = state.revealedNeuronCount

        guard targetCount > currentCount else { return }

        // Create new neuron entities
        for i in currentCount..<targetCount {
            let nodeDef = NetworkLayout.nodes[i]
            let entity = NeuronFactory.createNeuronEntity(position: nodeDef.position)
            entity.name = "neuron_\(i)"

            // Start invisible and scale in
            entity.scale = .zero
            anchor.addChild(entity)

            state.neurons.append(Neuron(position: nodeDef.position, entity: entity))

            // Animate appearance
            let finalTransform = Transform(
                scale: .one,
                rotation: .init(),
                translation: nodeDef.position
            )
            entity.move(
                to: finalTransform,
                relativeTo: anchor,
                duration: 0.5,
                timingFunction: .easeOut
            )
        }

        // Create axon connections for newly revealed neurons
        // Only create an axon if both the source AND destination neurons exist
        for i in currentCount..<targetCount {
            let nodeDef = NetworkLayout.nodes[i]
            for destIndex in nodeDef.connections {
                guard destIndex < targetCount else { continue }
                let srcNeuron = state.neurons[i]
                let dstNeuron = state.neurons[destIndex]

                let axonEntity = NeuronFactory.createAxonEntity(
                    from: srcNeuron.position,
                    to: dstNeuron.position
                )
                axonEntity.name = "axon_\(i)_\(destIndex)"

                // Start invisible
                axonEntity.scale = SIMD3<Float>(1, 0, 1) // squash along length
                anchor.addChild(axonEntity)

                var pathway = NeuralPathway(
                    sourceNeuronID: srcNeuron.id,
                    destinationNeuronID: dstNeuron.id,
                    axonEntity: axonEntity
                )
                state.pathways.append(pathway)

                // Animate axon appearing
                let fullTransform = axonEntity.transform
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    axonEntity.move(
                        to: fullTransform,
                        relativeTo: anchor,
                        duration: 0.4,
                        timingFunction: .easeOut
                    )
                }
                // Fix initial scale for animation
                axonEntity.scale = .one
            }
        }

        // Also check if previously revealed neurons have connections to newly revealed ones
        for i in 0..<currentCount {
            let nodeDef = NetworkLayout.nodes[i]
            for destIndex in nodeDef.connections {
                guard destIndex >= currentCount && destIndex < targetCount else { continue }
                let srcNeuron = state.neurons[i]
                let dstNeuron = state.neurons[destIndex]

                // Check we haven't already created this pathway
                let exists = state.pathways.contains {
                    $0.sourceNeuronID == srcNeuron.id && $0.destinationNeuronID == dstNeuron.id
                }
                guard !exists else { continue }

                let axonEntity = NeuronFactory.createAxonEntity(
                    from: srcNeuron.position,
                    to: dstNeuron.position
                )
                axonEntity.name = "axon_\(i)_\(destIndex)"
                anchor.addChild(axonEntity)

                let pathway = NeuralPathway(
                    sourceNeuronID: srcNeuron.id,
                    destinationNeuronID: dstNeuron.id,
                    axonEntity: axonEntity
                )
                state.pathways.append(pathway)
            }
        }

        state.revealedNeuronCount = targetCount
    }
}
