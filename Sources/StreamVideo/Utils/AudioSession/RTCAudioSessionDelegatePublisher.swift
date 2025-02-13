//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import StreamWebRTC

/// Enumeration representing all the events published by the delegate.
enum AudioSessionEvent {
    case didBeginInterruption(session: RTCAudioSession)

    case didEndInterruption(session: RTCAudioSession, shouldResumeSession: Bool)

    case didChangeRoute(
        session: RTCAudioSession,
        reason: AVAudioSession.RouteChangeReason,
        previousRoute: AVAudioSessionRouteDescription
    )

    case mediaServerTerminated(session: RTCAudioSession)

    case mediaServerReset(session: RTCAudioSession)

    case didChangeCanPlayOrRecord(
        session: RTCAudioSession,
        canPlayOrRecord: Bool
    )

    case didStartPlayOrRecord(session: RTCAudioSession)

    case didStopPlayOrRecord(session: RTCAudioSession)

    case didChangeOutputVolume(
        audioSession: RTCAudioSession,
        outputVolume: Float
    )

    case didDetectPlayoutGlitch(
        audioSession: RTCAudioSession,
        totalNumberOfGlitches: Int64
    )

    case willSetActive(audioSession: RTCAudioSession, active: Bool)

    case didSetActive(audioSession: RTCAudioSession, active: Bool)

    case failedToSetActive(
        audioSession: RTCAudioSession,
        active: Bool,
        error: Error
    )

    case audioUnitStartFailedWithError(
        audioSession: RTCAudioSession,
        error: Error
    )
}

// MARK: - Delegate Publisher Class

/// A delegate that publishes all RTCAudioSessionDelegate events via a Combine PassthroughSubject.
@objc
final class RTCAudioSessionDelegatePublisher: NSObject, RTCAudioSessionDelegate {

    /// The subject used to publish delegate events.
    private let subject = PassthroughSubject<AudioSessionEvent, Never>()

    /// A public publisher that subscribers can listen to.
    var publisher: AnyPublisher<AudioSessionEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    // MARK: - RTCAudioSessionDelegate Methods
    
    func audioSessionDidBeginInterruption(_ session: RTCAudioSession) {
        subject.send(.didBeginInterruption(session: session))
    }
    
    func audioSessionDidEndInterruption(
        _ session: RTCAudioSession,
        shouldResumeSession: Bool
    ) {
        subject.send(
            .didEndInterruption(
                session: session,
                shouldResumeSession: shouldResumeSession
            )
        )
    }
    
    func audioSessionDidChangeRoute(
        _ session: RTCAudioSession,
        reason: AVAudioSession.RouteChangeReason,
        previousRoute: AVAudioSessionRouteDescription
    ) {
        subject.send(
            .didChangeRoute(
                session: session,
                reason: reason,
                previousRoute: previousRoute
            )
        )
    }
    
    func audioSessionMediaServerTerminated(_ session: RTCAudioSession) {
        subject.send(.mediaServerTerminated(session: session))
    }
    
    func audioSessionMediaServerReset(_ session: RTCAudioSession) {
        subject.send(.mediaServerReset(session: session))
    }
    
    func audioSession(
        _ session: RTCAudioSession,
        didChangeCanPlayOrRecord canPlayOrRecord: Bool
    ) {
        subject.send(
            .didChangeCanPlayOrRecord(
                session: session,
                canPlayOrRecord: canPlayOrRecord
            )
        )
    }
    
    func audioSessionDidStartPlayOrRecord(_ session: RTCAudioSession) {
        subject.send(.didStartPlayOrRecord(session: session))
    }
    
    func audioSessionDidStopPlayOrRecord(_ session: RTCAudioSession) {
        subject.send(.didStopPlayOrRecord(session: session))
    }
    
    func audioSession(
        _ audioSession: RTCAudioSession,
        didChangeOutputVolume outputVolume: Float
    ) {
        subject.send(
            .didChangeOutputVolume(
                audioSession: audioSession,
                outputVolume: outputVolume
            )
        )
    }
    
    func audioSession(
        _ audioSession: RTCAudioSession,
        didDetectPlayoutGlitch totalNumberOfGlitches: Int64
    ) {
        subject.send(
            .didDetectPlayoutGlitch(
                audioSession: audioSession,
                totalNumberOfGlitches: totalNumberOfGlitches
            )
        )
    }
    
    func audioSession(
        _ audioSession: RTCAudioSession,
        willSetActive active: Bool
    ) {
        subject.send(
            .willSetActive(
                audioSession: audioSession,
                active: active
            )
        )
    }
    
    func audioSession(
        _ audioSession: RTCAudioSession,
        didSetActive active: Bool
    ) {
        subject.send(
            .didSetActive(
                audioSession: audioSession,
                active: active
            )
        )
    }
    
    func audioSession(
        _ audioSession: RTCAudioSession,
        failedToSetActive active: Bool,
        error: Error
    ) {
        subject.send(
            .failedToSetActive(
                audioSession: audioSession,
                active: active,
                error: error
            )
        )
    }
    
    func audioSession(
        _ audioSession: RTCAudioSession,
        audioUnitStartFailedWithError error: Error
    ) {
        subject.send(
            .audioUnitStartFailedWithError(
                audioSession: audioSession,
                error: error
            )
        )
    }
}
