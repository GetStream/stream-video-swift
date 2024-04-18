//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public final class NoiseCancellationFilter: AudioFilter {

    @Injected(\.streamVideo) private var streamVideo

    private let name: String
    private let initializeClosure: (Int, Int) -> Void
    private let processClosure: (Int, Int, Int, UnsafeMutablePointer<Float>) -> Void
    private let releaseClosure: () -> Void

    private var isActive: Bool = false
    private var activationTask: Task<Void, Never>?

    public init(
        name: String,
        initialize: @escaping (Int, Int) -> Void,
        process: @escaping (Int, Int, Int, UnsafeMutablePointer<Float>) -> Void,
        release: @escaping () -> Void
    ) {
        self.name = name
        initializeClosure = initialize
        processClosure = process
        releaseClosure = release
    }

    // MARK: - AudioFilter

    public var id: String { name }

    public func initialize(sampleRate: Int, channels: Int) {
        guard activationTask == nil else { return }
        
        activationTask = Task { @MainActor [weak self] in
            guard let activeCall = self?.streamVideo.state.activeCall else {
                self?.activationTask = nil
                return
            }

            do {
                try await activeCall.startNoiseCancellation()
                self?.initializeClosure(sampleRate, channels)
                self?.isActive = true
            } catch {
                log.error(error)
                self?.activationTask = nil
            }
        }

        log.debug("AudioFilter:\(id) initialize sampleRate:\(sampleRate) channels:\(channels).")
    }

    public func applyEffect(to buffer: inout RTCAudioBuffer) {
        guard isActive else { return }
        log.debug("AudioFilter:\(id) processing channels:\(buffer.channels) frames:\(buffer.frames).")
        processClosure(
            buffer.channels,
            buffer.bands,
            buffer.frames,
            buffer.rawBuffer(forChannel: 0)
        )
    }

    public func release() {
        Task { @MainActor in
            do {
                guard
                    let activeCall = streamVideo.state.activeCall
                else {
                    return
                }
                try await activeCall.stopNoiseCancellation()
            } catch {
                log.error(error)
            }
        }
        releaseClosure()
        log.debug("AudioFilter:\(id) release.")
    }
}
