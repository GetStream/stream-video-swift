//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import CoreMedia
import Foundation
import StreamVideo
import StreamWebRTC

final class PictureInPictureDataPipeline: Sendable {

    enum SizeEvent: CustomStringConvertible {
        case setPreferredSize(CGSize)
        case contentSizeUpdated(CGSize)

        var description: String {
            switch self {
            case let .setPreferredSize(size):
                return ".setPreferredSize(size:\(size))"
            case let .contentSizeUpdated(size):
                return ".contentSizeUpdated(size:\(size))"
            }
        }
    }

    enum Content: CustomStringConvertible, Equatable {
        case none
        case participant(CallParticipant, track: RTCVideoTrack)
        case screenSharing(CallParticipant, track: RTCVideoTrack)
        case `static`(CallParticipant)
        case reconnecting

        var description: String {
            switch self {
            case .none:
                ".none"
            case let .participant(callParticipant, track):
                ".participant(name:\(callParticipant.name), id:\(callParticipant.id), hasVideo:\(callParticipant.hasVideo), track id:\(track.trackId) isEnabled:\(track.isEnabled))"
            case let .screenSharing(callParticipant, track):
                ".screenSharing(name:\(callParticipant.name), id:\(callParticipant.id), hasVideo:\(callParticipant.hasVideo), track id:\(track.trackId) isEnabled:\(track.isEnabled))"
            case let .static(callParticipant):
                ".static(name:\(callParticipant.name), id:\(callParticipant.id), hasVideo:\(callParticipant.hasVideo))"
            case .reconnecting:
                ".reconnecting"
            }
        }

        static func == (lhs: Content, rhs: Content) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none):
                return true

            case (let .participant(_, lhsTrack), let .participant(_, rhsTrack)):
                return lhsTrack.trackId == rhsTrack.trackId

            case (let .screenSharing(_, lhsTrack), let .screenSharing(_, rhsTrack)):
                return lhsTrack.trackId == rhsTrack.trackId

            case let (.static(lhsParticipant), .static(rhsParticipant)):
                return lhsParticipant.sessionId == rhsParticipant.sessionId

            case (.reconnecting, .reconnecting):
                return true

            default:
                return false
            }
        }
    }

    private let contentSubject: PassthroughSubject<Content, Never> = .init()
    var contentPublisher: AnyPublisher<Content, Never> { contentSubject.eraseToAnyPublisher() }

    private let frameBufferSubject: PassthroughSubject<CMSampleBuffer, Never> = .init()
    var frameBufferPublisher: AnyPublisher<CMSampleBuffer, Never> { frameBufferSubject.eraseToAnyPublisher() }

    private let sizeEventSubject: PassthroughSubject<SizeEvent, Never> = .init()
    var sizeEventPublisher: AnyPublisher<SizeEvent, Never> { sizeEventSubject.eraseToAnyPublisher() }

    func send(_ frameBuffer: CMSampleBuffer) {
        frameBufferSubject.send(frameBuffer)
    }

    func setPreferredSize(_ size: CGSize) {
        sizeEventSubject.send(.setPreferredSize(size))
    }

    func contentSizeUpdated(_ size: CGSize) {
        sizeEventSubject.send(.contentSizeUpdated(size))
    }

    func send(_ content: Content) {
        contentSubject.send(content)
    }
}
