//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class WebRTCTrackStorage: @unchecked Sendable {

    private let accessingQueue = UnfairQueue()

    private var audioTracks: [String: RTCAudioTrack] = [:]
    private var videoTracks: [String: RTCVideoTrack] = [:]
    private var screenShareTracks: [String: RTCVideoTrack] = [:]

    /// Retrieves a track by ID and track type.
    ///
    /// - Parameters:
    ///   - id: The participant ID.
    ///   - trackType: The type of track (audio, video, screenshare).
    /// - Returns: The associated media stream track, or `nil` if not found.
    func track(
        for id: String,
        of trackType: TrackType
    ) -> RTCMediaStreamTrack? {
        accessingQueue.sync {
            switch trackType {
            case .audio:
                return audioTracks[id]
            case .video:
                return videoTracks[id]
            case .screenshare:
                return screenShareTracks[id]
            default:
                return nil
            }
        }
    }

    func addTrack(
        _ track: RTCMediaStreamTrack,
        type: TrackType,
        for id: String
    ) {
        accessingQueue.sync {
            switch type {
            case .audio:
                if let audioTrack = track as? RTCAudioTrack {
                    audioTracks[id] = audioTrack
                }
            case .video:
                if let videoTrack = track as? RTCVideoTrack {
                    videoTracks[id] = videoTrack
                }
            case .screenshare:
                if let videoTrack = track as? RTCVideoTrack {
                    screenShareTracks[id] = videoTrack
                }
            default:
                break
            }
        }
    }

    func removeTrack(for id: String, type: TrackType? = nil) {
        accessingQueue.sync {
            if let type {
                switch type {
                case .audio:
                    audioTracks[id] = nil
                case .video:
                    videoTracks[id] = nil
                case .screenshare:
                    screenShareTracks[id] = nil
                default:
                    break
                }
            } else {
                audioTracks[id] = nil
                videoTracks[id] = nil
                screenShareTracks[id] = nil
            }
        }
    }

    func removeAll() {
        accessingQueue.sync {
            audioTracks = [:]
            videoTracks = [:]
            screenShareTracks = [:]
        }
    }

    var snapshot: [String: TrackType] {
        var result: [String: TrackType] = [:]
        let audioTracks = accessingQueue.sync { self.audioTracks }
        let videoTracks = accessingQueue.sync { self.videoTracks }
        let screenShareTracks = accessingQueue.sync { self.screenShareTracks }

        audioTracks.forEach { result[$0.key] = .audio }
        videoTracks.forEach { result[$0.key] = .video }
        screenShareTracks.forEach { result[$0.key] = .screenshare }

        return result
    }
}
