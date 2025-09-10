//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension LocalAudioMediaAdapter.Namespace {

    struct StoreState: Equatable, CustomStringConvertible {
        var sessionID: String
        var streamIds: [String]
        var publishOptions: [PublishOptions.AudioPublishOptions]
        var mediaConstraints: RTCMediaConstraints
        var audioBitrate: AudioBitrate
        var peerConnection: StreamRTCPeerConnectionProtocol
        var peerConnectionFactory: PeerConnectionFactory
        var sfuAdapter: SFUAdapter
        var availableTrackStates: [TrackState]
        var callSettings: CallSettings.Audio?
        var ownCapabilities: Set<OwnCapability>
        var subject: PassthroughSubject<TrackEvent, Never>
        var publishingState: PublishingState

        static func == (
            lhs: LocalAudioMediaAdapter.Namespace.StoreState,
            rhs: LocalAudioMediaAdapter.Namespace.StoreState
        ) -> Bool {
            lhs.sessionID == rhs.sessionID
                && lhs.streamIds == rhs.streamIds
                && lhs.publishOptions == rhs.publishOptions
                && lhs.mediaConstraints == rhs.mediaConstraints
                && lhs.audioBitrate == rhs.audioBitrate
                && lhs.peerConnection === rhs.peerConnection
                && lhs.peerConnectionFactory === rhs.peerConnectionFactory
                && lhs.sfuAdapter === rhs.sfuAdapter
                && lhs.availableTrackStates == rhs.availableTrackStates
                && lhs.callSettings == rhs.callSettings
                && lhs.ownCapabilities == rhs.ownCapabilities
                && lhs.subject === rhs.subject
                && lhs.publishingState == rhs.publishingState
        }

        var description: String {
            "<State sessionID:\(sessionID) streamIds:\(streamIds) publishOptions:[\(publishOptions.map(\.codec))] sfuAdapter:\(sfuAdapter.hostname) callSettings:\(String(describing: callSettings)) hasAudioCapability:\(ownCapabilities.contains(.sendAudio)) publishingState:\(publishingState) audioBitrate:\(audioBitrate)/>"
        }
    }
}

extension LocalAudioMediaAdapter.Namespace.StoreState {

    enum PublishingState: Equatable, Sendable, CustomStringConvertible {
        case idle
        case processing(isMuted: Bool, trackState: TrackState)
        case unmuted(TrackState)
        case muted(TrackState)

        var description: String {
            switch self {
            case .idle:
                return ".idle"
            case let .processing(isMuted, trackState):
                return ".processing(isMuted:\(isMuted) trackState:\(trackState))"
            case let .unmuted(trackState):
                return ".unmuted(\(trackState))"
            case let .muted(trackState):
                return ".muted(\(trackState))"
            }
        }
    }

    struct TrackState: Equatable, Sendable, CustomStringConvertible {
        var primaryTrack: RTCAudioTrack
        var audioSource: RTCAudioSource
        var mediaConstraints: RTCMediaConstraints
        var audioBitrate: AudioBitrate
        var transceiverStorage: MediaTransceiverStorage<PublishOptions.AudioPublishOptions>

        static func == (
            lhs: LocalAudioMediaAdapter.Namespace.StoreState.TrackState,
            rhs: LocalAudioMediaAdapter.Namespace.StoreState.TrackState
        ) -> Bool {
            lhs.primaryTrack.trackId == rhs.primaryTrack.trackId
                && lhs.audioSource === rhs.audioSource
                && lhs.mediaConstraints == rhs.mediaConstraints
        }

        var description: String {
            "<TrackState trackId:\(primaryTrack.trackId) hasHiFiMediaConstraints:\(mediaConstraints == .hiFiAudioConstraints) audioBitrate:\(audioBitrate)/>"
        }
    }
}
