//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Renders injected audio buffers through an AVAudioEngine graph.
final class AudioBufferRenderer {

    /// A stable identifier for diagnostics.
    let identifier = UUID()

    private var context: AVAudioEngine.InputContext?
    private let playerNode = AVAudioPlayerNode()
    private let mixerNode = AVAudioMixerNode()
    private let audioConverter = AudioConverter()

    // MARK: - Called from AudioBufferCapturer

    /// Enqueues a ReplayKit audio sample buffer for playback.
    func enqueue(_ sampleBuffer: CMSampleBuffer) {
        guard
            let context
        else {
            return
        }

        let info = sampleBuffer.rmsAndPeak

        guard
            !info.isSilent
        else {
            return
        }

        guard
            let inputBuffer = AVAudioPCMBuffer.from(sampleBuffer)
        else {
            return
        }

        guard
            let outputBuffer = audioConverter.convertIfRequired(
                inputBuffer,
                to: context.format
            )
        else {
            return
        }

        self.enqueue(outputBuffer)
    }

    // MARK: - Called from AudioDeviceModule

    /// Configures the renderer with the active audio engine input context.
    func configure(
        with newContext: AVAudioEngine.InputContext?
    ) {
        if context?.engine !== newContext?.engine, context != nil {
            reset()
        }

        self.context = newContext

        guard let context else {
            log.debug(
                "Audio renderer unconfigured. rendererId=\(identifier)",
                subsystems: .audioRecording
            )
            return
        }

        #if STREAM_TESTS
        // Avoid making changes to AVAudioEngine instances during tests as they
        // cause crashes.
        #else
        attachIfNeeded(playerNode, to: context.engine)
        attachIfNeeded(mixerNode, to: context.engine)

        context.engine.disconnectNodeOutput(playerNode)
        context.engine.disconnectNodeOutput(mixerNode)

        if let source = context.source {
            context.engine.disconnectNodeOutput(source)
            context.engine.connect(
                source,
                to: mixerNode,
                format: context.format
            )
            context.engine.connect(
                playerNode,
                to: mixerNode,
                format: context.format
            )
            context.engine.connect(
                mixerNode,
                to: context.destination,
                format: context.format
            )
        } else {
            context.engine.connect(
                playerNode,
                to: context.destination,
                format: context.format
            )
        }
        #endif

        log.debug(
            "Audio renderer configured. rendererId=\(identifier)"
                + " sampleRateHz=\(context.format.sampleRate) channels=\(context.format.channelCount)"
                + " format=\(context.format.commonFormat.rawValue) interleaved=\(context.format.isInterleaved)",
            subsystems: .audioRecording
        )
    }

    /// Stops playback without tearing down the engine graph.
    func stop() {
        guard playerNode.isPlaying else {
            return
        }
        playerNode.stop()
    }

    /// Resets the graph and converter state for a new session.
    func reset() {
        guard
            let engine = context?.engine
        else {
            context = nil
            log.debug("Audio renderer reset. rendererId=\(identifier)", subsystems: .audioRecording)
            return
        }

        playerNode.stop()
        audioConverter.reset()
        #if STREAM_TESTS
        // Avoid making changes to AVAudioEngine instances during tests as they
        // cause crashes.
        #else
        engine.disconnectNodeOutput(playerNode)
        engine.disconnectNodeOutput(mixerNode)
        detachIfNeeded(playerNode, from: engine)
        detachIfNeeded(mixerNode, from: engine)
        #endif
        context = nil
        log.debug("Audio renderer reset. rendererId=\(identifier)", subsystems: .audioRecording)
    }

    // MARK: - Private Helpers

    private func playIfRequired() {
        guard
            let context
        else {
            log.warning(
                "Audio playback unavailable. rendererId=\(identifier) reason=contextMissing",
                subsystems: .audioRecording
            )
            return
        }

        guard !playerNode.isPlaying else {
            return
        }

        guard
            playerNode.engine != nil,
            playerNode.engine === context.engine
        else {
            log
                .warning(
                    "Audio playback unavailable. rendererId=\(identifier)"
                        + " reason=engineMismatch engineAttached=\(playerNode.engine != nil)",
                    subsystems: .audioRecording
                )
            return
        }
        playerNode.play()
        log.debug("Audio playback started. rendererId=\(identifier)", subsystems: .audioRecording)
    }

    private func enqueue(_ buffer: AVAudioPCMBuffer) {
        let info = buffer.rmsAndPeak

        guard !info.isSilent else {
            return
        }

        playIfRequired()

        guard playerNode.isPlaying else {
            return
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }

    private func attachIfNeeded(
        _ node: AVAudioNode,
        to engine: AVAudioEngine
    ) {
        let isAttached = engine.attachedNodes.contains { $0 === node }
        if !isAttached {
            engine.attach(node)
        }
    }

    private func detachIfNeeded(
        _ node: AVAudioNode,
        from engine: AVAudioEngine
    ) {
        let isAttached = engine.attachedNodes.contains { $0 === node }
        if isAttached {
            engine.detach(node)
        }
    }
}
