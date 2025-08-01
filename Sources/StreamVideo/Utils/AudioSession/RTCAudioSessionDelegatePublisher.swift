//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import StreamWebRTC

/// Enumeration representing all the events published by the delegate.
enum AudioSessionEvent: @unchecked Sendable, CustomStringConvertible, Encodable {
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

     var description: String {
        switch self {
        case let .didBeginInterruption(session):
            return ".didBeginInterruption(session:\(session))"
        case let .didEndInterruption(session, shouldResumeSession):
            return ".didEndInterruption(session:\(session), shouldResumeSession:\(shouldResumeSession))"
        case let .didChangeRoute(session, reason, previousRoute):
            return ".didChangeRoute(session:\(session), reason:\(reason), previousRoute:\(previousRoute))"
        case let .mediaServerTerminated(session):
            return ".mediaServerTerminated(session:\(session))"
        case let .mediaServerReset(session):
            return ".mediaServerReset(session:\(session))"
        case let .didChangeCanPlayOrRecord(session, canPlayOrRecord):
            return ".didChangeCanPlayOrRecord(session:\(session), canPlayOrRecord:\(canPlayOrRecord))"
        case let .didStartPlayOrRecord(session):
            return ".didStartPlayOrRecord(session:\(session))"
        case let .didStopPlayOrRecord(session):
            return ".didStopPlayOrRecord(session:\(session))"
        case let .didChangeOutputVolume(audioSession, outputVolume):
            return ".didChangeOutputVolume(audioSession:\(audioSession), outputVolume:\(outputVolume))"
        case let .didDetectPlayoutGlitch(audioSession, totalNumberOfGlitches):
            return ".didDetectPlayoutGlitch(audioSession:\(audioSession), totalNumberOfGlitches:\(totalNumberOfGlitches))"
        case let .willSetActive(audioSession, active):
            return ".willSetActive(audioSession:\(audioSession), active:\(active))"
        case let .didSetActive(audioSession, active):
            return ".didSetActive(audioSession:\(audioSession), active:\(active))"
        case let .failedToSetActive(audioSession, active, error):
            return ".failedToSetActive(audioSession:\(audioSession), active:\(active), error:\(error))"
        case let .audioUnitStartFailedWithError(audioSession, error):
            return ".audioUnitStartFailedWithError(audioSession:\(audioSession), error:\(error))"
        }
    }

    var title: String {
        switch self {
        case .didBeginInterruption:
            return ".didBeginInterruption"
        case .didEndInterruption:
            return ".didEndInterruption"
        case .didChangeRoute:
            return ".didChangeRoute"
        case .mediaServerTerminated:
            return ".mediaServerTerminated"
        case .mediaServerReset:
            return ".mediaServerReset"
        case .didChangeCanPlayOrRecord:
            return ".didChangeCanPlayOrRecord"
        case .didStartPlayOrRecord:
            return ".didStartPlayOrRecord"
        case .didStopPlayOrRecord:
            return ".didStopPlayOrRecord"
        case .didChangeOutputVolume:
            return ".didChangeOutputVolume"
        case .didDetectPlayoutGlitch:
            return ".didDetectPlayoutGlitch"
        case .willSetActive:
            return ".willSetActive"
        case .didSetActive:
            return ".didSetActive"
        case .failedToSetActive:
            return ".failedToSetActive"
        case .audioUnitStartFailedWithError:
            return ".audioUnitStartFailedWithError"
        }
    }

    // MARK: - Custom Encoding Keys

    private enum CodingKeys: String, CodingKey {
        case type
        case shouldResumeSession
        case reason
        case previousRoute
        case canPlayOrRecord
        case outputVolume
        case totalNumberOfGlitches
        case active
        case errorDescription
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .didBeginInterruption:
            try container.encode("didBeginInterruption", forKey: .type)

        case let .didEndInterruption(_, shouldResumeSession):
            try container.encode("didEndInterruption", forKey: .type)
            try container.encode(shouldResumeSession, forKey: .shouldResumeSession)

        case let .didChangeRoute(_, reason, previousRoute):
            try container.encode("didChangeRoute", forKey: .type)
            try container.encode(reason.rawValue, forKey: .reason)
            // AVAudioSessionRouteDescription is not Encodable, encode a summary string instead
            try container.encode(previousRoute.description, forKey: .previousRoute)

        case .mediaServerTerminated:
            try container.encode("mediaServerTerminated", forKey: .type)

        case .mediaServerReset:
            try container.encode("mediaServerReset", forKey: .type)

        case let .didChangeCanPlayOrRecord(_, canPlayOrRecord):
            try container.encode("didChangeCanPlayOrRecord", forKey: .type)
            try container.encode(canPlayOrRecord, forKey: .canPlayOrRecord)

        case .didStartPlayOrRecord:
            try container.encode("didStartPlayOrRecord", forKey: .type)

        case .didStopPlayOrRecord:
            try container.encode("didStopPlayOrRecord", forKey: .type)

        case let .didChangeOutputVolume(_, outputVolume):
            try container.encode("didChangeOutputVolume", forKey: .type)
            try container.encode(outputVolume, forKey: .outputVolume)

        case let .didDetectPlayoutGlitch(_, totalNumberOfGlitches):
            try container.encode("didDetectPlayoutGlitch", forKey: .type)
            try container.encode(totalNumberOfGlitches, forKey: .totalNumberOfGlitches)

        case let .willSetActive(_, active):
            try container.encode("willSetActive", forKey: .type)
            try container.encode(active, forKey: .active)

        case let .didSetActive(_, active):
            try container.encode("didSetActive", forKey: .type)
            try container.encode(active, forKey: .active)

        case let .failedToSetActive(_, active, error):
            try container.encode("failedToSetActive", forKey: .type)
            try container.encode(active, forKey: .active)
            try container.encode(error.localizedDescription, forKey: .errorDescription)

        case let .audioUnitStartFailedWithError(_, error):
            try container.encode("audioUnitStartFailedWithError", forKey: .type)
            try container.encode(error.localizedDescription, forKey: .errorDescription)
        }
    }
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

#if compiler(>=6.0)
extension RTCAudioSession: @retroactive Encodable {}
#else
extension RTCAudioSession: Encodable {}
#endif

extension RTCAudioSession {

    enum CodingKeys: String, CodingKey {
        case isActive
        case category
        case mode
        case useManualAudio
        case isAudioEnabled
        case device
        case deviceIsExternal = "device.isExternal"
        case deviceIsSpeaker = "device.isSpeaker"
        case deviceIsReceiver = "device.isReceiver"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(category, forKey: .category)
        try container.encode(mode, forKey: .mode)
        try container.encode("\(currentRoute)", forKey: .device)
        try container.encode(currentRoute.isExternal, forKey: .deviceIsExternal)
        try container.encode(currentRoute.isSpeaker, forKey: .deviceIsSpeaker)
        try container.encode(currentRoute.isReceiver, forKey: .deviceIsReceiver)
        try container.encode(useManualAudio, forKey: .useManualAudio)
        try container.encode(isAudioEnabled, forKey: .isAudioEnabled)
    }
}
