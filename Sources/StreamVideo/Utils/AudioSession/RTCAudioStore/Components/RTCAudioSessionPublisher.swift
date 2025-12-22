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

        static func == (lhs: Event, rhs: Event) -> Bool {
            switch (lhs, rhs) {
            case (.didBeginInterruption, .didBeginInterruption):
                return true

            case (let .didEndInterruption(lhsValue), let .didEndInterruption(rhsValue)):
                return lhsValue == rhsValue

            case (let .didChangeRoute(lReason, lFrom, lTo), let .didChangeRoute(rReason, rFrom, rTo)):
                return lReason == rReason
                    && RTCAudioStore.StoreState.AudioRoute(lFrom) == RTCAudioStore.StoreState.AudioRoute(rFrom)
                    && RTCAudioStore.StoreState.AudioRoute(lTo) == RTCAudioStore.StoreState.AudioRoute(rTo)

            default:
                return false
            }
        }
    }

    /// The Combine publisher that emits session events.
    private(set) lazy var publisher: AnyPublisher<Event, Never> = subject.eraseToAnyPublisher()

    private let source: RTCAudioSession
    private let subject: PassthroughSubject<Event, Never> = .init()

    /// Creates a publisher for the provided WebRTC audio session.
    /// - Parameter source: The session to observe.
    init(_ source: RTCAudioSession) {
        self.source = source
        super.init()
        _ = publisher
        source.add(self)
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
