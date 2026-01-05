//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A concrete implementation of `AudioFilter` that applies noise cancellation effects.
public final class NoiseCancellationFilter: AudioFilter, @unchecked Sendable, ObservableObject {

    public typealias InitializeClosure = (Int, Int) -> Void
    public typealias ProcessClosure = (Int, Int, Int, UnsafeMutablePointer<Float>) -> Void
    public typealias ReleaseClosure = () -> Void

    @Published public private(set) var isActive: Bool = false
    private var activationTask: Task<Void, Error>?

    private let name: String
    private let initializeClosure: (Int, Int) -> Void
    private let processClosure: (Int, Int, Int, UnsafeMutablePointer<Float>) -> Void
    private let releaseClosure: () -> Void
    private var activeCallCancellable: AnyCancellable?
    private let serialQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private let disposableBag = DisposableBag()
    private weak var activeCall: Call? {
        didSet { didUpdateActiveCall(activeCall, oldValue: oldValue) }
    }

    weak var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
    }

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
        serialQueue.addTaskOperation { @MainActor [weak self] in
            guard let self, !isActive else { return }
            initializeClosure(sampleRate, channels)
            isActive = true
            log.debug("AudioFilter:\(id) initialize sampleRate:\(sampleRate) channels:\(channels).")
        }
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
        serialQueue.addTaskOperation { [weak self] in
            guard let self, let activeCall else {
                return
            }
            await stopNoiseCancellation(for: activeCall)
            log.debug("AudioFilter:\(id) release.")
        }
    }

    // MARK: - Private helpers

    private func didUpdate(_ streamVideo: StreamVideo?) {
        activeCallCancellable?.cancel()
        activeCall = nil

        guard let streamVideo else {
            return
        }

        activeCallCancellable = streamVideo
            .state
            .$activeCall
            .assign(to: \.activeCall, onWeak: self)
    }

    private func didUpdateActiveCall(_ call: Call?, oldValue: Call?) {
        serialQueue.addTaskOperation { [weak self] in
            guard let self else { return }

            if let call, isActive {
                do {
                    try await call.startNoiseCancellation()
                    log.debug("AudioFilter:\(id) is now active 🟢.")
                } catch {
                    release()
                    log.debug("AudioFilter:\(id) failed to activate with error:\(error)")
                }
            } else if call == nil, isActive {
                await stopNoiseCancellation(for: oldValue)
            }
        }
    }

    private func stopNoiseCancellation(for call: Call?) async {
        guard isActive else {
            return
        }
        _ = await Task(disposableBag: disposableBag) { @MainActor [weak self] in
            self?.isActive = false
        }.result
        releaseClosure() // Invoke the release closure.
        log.debug("AudioFilter:\(id) is now inactive 🔴.")
        
        guard let call else {
            return
        }

        do {
            try await call.stopNoiseCancellation()
        } catch {
            log.error(error)
        }
    }
}
