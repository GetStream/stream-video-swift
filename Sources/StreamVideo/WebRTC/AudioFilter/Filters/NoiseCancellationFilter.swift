//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A concrete implementation of `AudioFilter` that applies noise cancellation effects.
public final class NoiseCancellationFilter: AudioFilter, @unchecked Sendable {

    public typealias InitializeClosure = (Int, Int) -> Void
    public typealias ProcessClosure = (Int, Int, Int, UnsafeMutablePointer<Float>) -> Void
    public typealias ReleaseClosure = () -> Void

    @Injected(\.streamVideo) private var streamVideo

    private var isActive: Bool = false
    private var activationTask: Task<Void, Error>?

    private let name: String
    private let initializeClosure: (Int, Int) -> Void
    private let processClosure: (Int, Int, Int, UnsafeMutablePointer<Float>) -> Void
    private let releaseClosure: () -> Void

    /// Initializes a new instance of `NoiseCancellationFilter`.
    /// - Parameters:
    ///   - name: The name identifier for the filter.
    ///   - initialize: The closure to initialize the filter with sample rate and channels.
    ///   - process: The closure to apply noise cancellation processing.
    ///   - release: The closure to release the filter.
    public init(
        name: String,
        initialize: @escaping InitializeClosure,
        process: @escaping ProcessClosure,
        release: @escaping ReleaseClosure
    ) {
        self.name = name
        initializeClosure = initialize
        processClosure = process
        releaseClosure = release
    }

    // MARK: - AudioFilter

    /// The identifier of the filter.
    public var id: String { name }

    /// Initializes the filter with the specified sample rate and number of channels.
    /// - Parameters:
    ///   - sampleRate: The sample rate in Hz.
    ///   - channels: The number of audio channels.
    public func initialize(sampleRate: Int, channels: Int) {
        guard activationTask == nil, !isActive else { return }

        let id = self.id
        // Asynchronously activate noise cancellation for the active call.
        activationTask = Task { @MainActor [weak self] in
            guard let activeCall = self?.streamVideo.state.activeCall else {
                self?.activationTask = nil
                log.warning("AudioFilter:\(id) cannot be activated. No activeCall found.")
                return
            }

            do {
                try await activeCall.startNoiseCancellation()
                self?.initializeClosure(sampleRate, channels)
                self?.isActive = true
                self?.activationTask = nil
                log.debug("AudioFilter:\(id) is now active 🟢.")
            } catch {
                self?.activationTask = nil
                log.debug("AudioFilter:\(id) failed to activate with error:\(error)")
            }
        }

        log.debug("AudioFilter:\(id) initialize sampleRate:\(sampleRate) channels:\(channels).")
    }

    /// Applies noise cancellation processing to the audio buffer.
    /// - Parameter buffer: The audio buffer to which the effect is applied.
    public func applyEffect(to buffer: inout RTCAudioBuffer) {
        guard isActive else {
            log.debug("AudioFilter:\(id) received an audioBuffer to process, while it's not active.")
            return
        }
        processClosure(
            buffer.channels,
            buffer.bands,
            buffer.frames,
            buffer.rawBuffer(forChannel: 0)
        )
    }

    /// Releases the filter by stopping noise cancellation for the active call.
    public func release() {
        Task { @MainActor in
            do {
                guard let activeCall = streamVideo.state.activeCall else {
                    return
                }
                try await activeCall.stopNoiseCancellation()
            } catch {
                log.error(error)
            }
        }
        activationTask = nil
        isActive = false
        releaseClosure() // Invoke the release closure.
        log.debug("AudioFilter:\(id) release.")
    }
}
