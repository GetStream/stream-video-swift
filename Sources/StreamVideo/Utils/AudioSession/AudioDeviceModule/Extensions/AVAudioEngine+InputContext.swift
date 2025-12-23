//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension AVAudioEngine {
    /// Captures the input wiring for an audio engine.
    ///
    /// This snapshot is passed across components so they can attach nodes using
    /// the same engine instance and connect them with a consistent format.
    struct InputContext: Equatable {
        /// The engine that owns the input/output graph.
        var engine: AVAudioEngine
        /// The optional upstream node that feeds the input chain.
        var source: AVAudioNode?
        /// The node that receives the input stream for rendering.
        var destination: AVAudioNode
        /// The audio format that the graph expects.
        var format: AVAudioFormat

        static func == (
            lhs: InputContext,
            rhs: InputContext
        ) -> Bool {
            // Engine identity must match to avoid cross-engine wiring.
            lhs.engine === rhs.engine
                // Nodes are compared for structural equality.
                && lhs.source == rhs.source
                && lhs.destination == rhs.destination
                // Formats must match to avoid converter mismatches.
                && lhs.format == rhs.format
        }
    }
}
