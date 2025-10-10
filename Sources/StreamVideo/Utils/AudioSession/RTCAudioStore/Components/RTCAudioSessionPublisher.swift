//
//  RTCAudioSessionPublisher.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import Combine
import StreamWebRTC

final class RTCAudioSessionPublisher: NSObject, RTCAudioSessionDelegate, @unchecked Sendable {

    enum Event {
        case didBeginInterruption

        case didEndInterruption(shouldResumeSession: Bool)

        case didChangeRoute(
            reason: AVAudioSession.RouteChangeReason,
            from: AVAudioSessionRouteDescription,
            to: AVAudioSessionRouteDescription
        )
    }

    private(set) lazy var publisher: AnyPublisher<Event, Never> = subject.eraseToAnyPublisher()

    private let source: RTCAudioSession
    private let subject: PassthroughSubject<Event, Never> = .init()


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
