//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Publishes significant `RTCAudioSessionDelegate` callbacks as Combine
/// events so middleware can react declaratively.
final class RTCAudioSessionPublisher: NSObject, RTCAudioSessionDelegate, @unchecked Sendable {

    /// Events emitted when the WebRTC audio session changes state.
    enum Event: Equatable {
        case didBeginInterruption

        case didEndInterruption(shouldResumeSession: Bool)

        case didChangeRoute(
            reason: AVAudioSession.RouteChangeReason,
            from: AVAudioSessionRouteDescription,
            to: AVAudioSessionRouteDescription
        )

        case didChangeCategory(AVAudioSession.Category)
        case didChangeMode(AVAudioSession.Mode)
    }

    /// The Combine publisher that emits session events.
    private(set) lazy var publisher: AnyPublisher<Event, Never> = subject.eraseToAnyPublisher()

    private let source: RTCAudioSession
    private let subject: PassthroughSubject<Event, Never> = .init()
    private let disposableBag = DisposableBag()

    /// Creates a publisher for the provided WebRTC audio session.
    /// - Parameter source: The session to observe.
    init(_ source: RTCAudioSession) {
        self.source = source
        super.init()
        _ = publisher
        source.add(self)

        DefaultTimer
            .publish(every: 0.1)
            .compactMap { [weak source] _ in source?.session.category }
            .removeDuplicates()
            .sink { [weak self] in self?.subject.send(.didChangeCategory($0)) }
            .store(in: disposableBag)

        DefaultTimer
            .publish(every: 0.1)
            .compactMap { [weak source] _ in source?.session.mode }
            .removeDuplicates()
            .sink { [weak self] in self?.subject.send(.didChangeMode($0)) }
            .store(in: disposableBag)
    }

    deinit {
        source.remove(self)
    }

    // MARK: - RTCAudioSessionDelegate

    func audioSessionDidBeginInterruption(_ session: RTCAudioSession) {
        subject.send(.didBeginInterruption)
    }

    func audioSessionDidEndInterruption(
        _ session: RTCAudioSession,
        shouldResumeSession: Bool
    ) {
        subject.send(.didEndInterruption(shouldResumeSession: shouldResumeSession))
    }

    /// Forwards route change notifications and includes the new route in the
    /// payload.
    func audioSessionDidChangeRoute(
        _ session: RTCAudioSession,
        reason: AVAudioSession.RouteChangeReason,
        previousRoute: AVAudioSessionRouteDescription
    ) {
        subject.send(
            .didChangeRoute(
                reason: reason,
                from: previousRoute,
                to: session.currentRoute
            )
        )
    }
}
