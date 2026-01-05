//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A thread-safe storage container for WebRTC media stream tracks.
///
/// This storage provides access and management for audio, video, and
/// screen share tracks, organizing them by participant ID. All mutations
/// and reads are synchronized on a dedicated queue to ensure thread safety
/// when accessed concurrently from multiple threads in the WebRTC pipeline.
final class WebRTCTrackStorage: @unchecked Sendable {

    /// An unfair locking queue used to synchronize all storage access.
    private let accessingQueue = UnfairQueue()

    /// A dictionary of audio tracks keyed by participant ID.
    private var audioTracks: [String: RTCAudioTrack] = [:]
    /// A dictionary of video tracks keyed by participant ID.
    private var videoTracks: [String: RTCVideoTrack] = [:]
    /// A dictionary of screen share video tracks keyed by participant ID.
    private var screenShareTracks: [String: RTCVideoTrack] = [:]

    /// Retrieves a media stream track for a given participant and type.
    ///
    /// - Parameters:
    ///   - id: The participant ID whose track should be fetched.
    ///   - trackType: The type of the track (audio, video, or screenshare).
    /// - Returns: The media stream track if found, otherwise `nil`.
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

    /// Adds a media stream track to storage for the specified participant and type.
    ///
    /// - Parameters:
    ///   - track: The media stream track to add.
    ///   - type: The type of the track (audio, video, or screenshare).
    ///   - id: The participant ID to associate with this track.
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

    /// Removes a specific track (or all tracks) for a participant.
    ///
    /// - Parameters:
    ///   - id: The participant ID whose track(s) should be removed.
    ///   - type: The type of track to remove (optional). If `nil`, removes all.
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

    /// Removes all stored tracks from storage for all participants.
    func removeAll() {
        accessingQueue.sync {
            audioTracks = [:]
            videoTracks = [:]
            screenShareTracks = [:]
        }
    }

    /// A snapshot mapping participant IDs to the type of their stored track.
    ///
    /// This returns a dictionary containing the current IDs and their associated
    /// track type, regardless of the actual underlying track object.
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
