//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreGraphics
import Foundation
import StreamWebRTC

/// Reports the first rendered remote audio and video frames for a join attempt.
///
/// The reporter registers itself as a renderer on remote RTC media tracks and
/// removes itself after the first frame of each media kind is observed.
final class MediaFrameReporter: NSObject, @unchecked Sendable, RTCVideoRenderer, RTCAudioRenderer {
    /// Stores renderer state behind actor isolation.
    private let storage: MediaFrameReporterStorage

    /// Creates a reporter that emits client events through the supplied reporter.
    /// - Parameter clientEventReporter: Reporter used for client-event delivery.
    init(clientEventReporter: ClientEventReporting) {
        storage = .init(clientEventReporter: clientEventReporter)
        super.init()
    }

    /// Starts a fresh reporting window for a new join attempt.
    /// - Parameter details: Event details attached to frame reports.
    func reset(details: ClientEventStageDetails) async {
        await storage.reset(details: details, renderer: self)
    }

    /// Registers this reporter on a remote media track when still needed.
    /// - Parameters:
    ///   - track: Track to observe for rendered frames.
    ///   - type: Media kind represented by the track.
    func add(_ track: RTCMediaStreamTrack, type: TrackType) async {
        await storage.add(track, type: type, renderer: self)
    }

    /// Removes this reporter from a previously observed track.
    /// - Parameters:
    ///   - track: Track that no longer needs frame observation.
    ///   - type: Media kind represented by the track.
    func remove(_ track: RTCMediaStreamTrack, type: TrackType) async {
        await storage.remove(track, type: type, renderer: self)
    }

    /// Removes this reporter from all currently observed tracks.
    func removeAllTracks() async {
        await storage.removeAllTracks(renderer: self)
    }

    /// Receives video-size updates required by ``RTCVideoRenderer``.
    func setSize(_ size: CGSize) {}

    /// Reports the first rendered remote video frame.
    /// - Parameter frame: Rendered frame supplied by WebRTC.
    func renderFrame(_ frame: RTCVideoFrame?) {
        guard frame != nil else { return }
        Task { await storage.report(.firstVideoFrame, renderer: self) }
    }

    /// Reports the first rendered remote audio frame.
    /// - Parameter pcmBuffer: Rendered audio buffer supplied by WebRTC.
    func render(pcmBuffer: AVAudioPCMBuffer) {
        Task { await storage.report(.firstAudioFrame, renderer: self) }
    }
}

/// Actor-isolated state for ``MediaFrameReporter``.
private actor MediaFrameReporterStorage {
    /// Delivers first-frame events to the backend.
    private let clientEventReporter: ClientEventReporting

    /// Details attached to first-frame reports for the current join attempt.
    private var details: ClientEventStageDetails = .init()
    /// Whether the current join attempt has reported a video frame.
    private var didReportVideoFrame = false
    /// Whether the current join attempt has reported an audio frame.
    private var didReportAudioFrame = false
    /// Remote video tracks currently observed for first-frame delivery.
    private var videoTracks: [ObjectIdentifier: RTCVideoTrack] = [:]
    /// Remote audio tracks currently observed for first-frame delivery.
    private var audioTracks: [ObjectIdentifier: RTCAudioTrack] = [:]

    /// Creates actor-isolated storage for the media frame reporter.
    ///
    /// - Parameter clientEventReporter: Reporter used for client-event
    ///   delivery.
    init(clientEventReporter: ClientEventReporting) {
        self.clientEventReporter = clientEventReporter
    }

    /// Starts a fresh first-frame reporting window.
    ///
    /// - Parameters:
    ///   - details: Event details attached to the next first-frame reports.
    ///   - renderer: Renderer to detach from tracks left by the old window.
    func reset(details: ClientEventStageDetails, renderer: MediaFrameReporter) {
        removeAllTracks(renderer: renderer)
        self.details = details
        didReportVideoFrame = false
        didReportAudioFrame = false
    }

    /// Attaches the renderer to a track when that media kind still needs a
    /// first-frame report.
    ///
    /// - Parameters:
    ///   - track: Remote media track to observe.
    ///   - type: Media kind represented by the track.
    ///   - renderer: Renderer to attach to the track.
    func add(
        _ track: RTCMediaStreamTrack,
        type: TrackType,
        renderer: MediaFrameReporter
    ) {
        switch type {
        case .audio:
            guard let track = track as? RTCAudioTrack, !didReportAudioFrame else { return }
            let id = ObjectIdentifier(track)
            guard audioTracks[id] == nil else { return }
            audioTracks[id] = track
            track.add(renderer)
        case .video, .screenshare:
            guard let track = track as? RTCVideoTrack, !didReportVideoFrame else { return }
            let id = ObjectIdentifier(track)
            guard videoTracks[id] == nil else { return }
            videoTracks[id] = track
            track.add(renderer)
        default:
            return
        }
    }

    /// Detaches the renderer from a track that is no longer active.
    ///
    /// - Parameters:
    ///   - track: Remote media track to stop observing.
    ///   - type: Media kind represented by the track.
    ///   - renderer: Renderer to detach from the track.
    func remove(
        _ track: RTCMediaStreamTrack,
        type: TrackType,
        renderer: MediaFrameReporter
    ) {
        switch type {
        case .audio:
            guard let track = track as? RTCAudioTrack else { return }
            audioTracks.removeValue(forKey: ObjectIdentifier(track))?.remove(renderer)
        case .video, .screenshare:
            guard let track = track as? RTCVideoTrack else { return }
            videoTracks.removeValue(forKey: ObjectIdentifier(track))?.remove(renderer)
        default:
            return
        }
    }

    /// Detaches the renderer from all observed tracks.
    ///
    /// - Parameter renderer: Renderer to detach from each observed track.
    func removeAllTracks(renderer: MediaFrameReporter) {
        let videoTracksToDetach = Array(videoTracks.values)
        let audioTracksToDetach = Array(audioTracks.values)
        videoTracks.removeAll()
        audioTracks.removeAll()
        videoTracksToDetach.forEach { $0.remove(renderer) }
        audioTracksToDetach.forEach { $0.remove(renderer) }
    }

    /// Reports the first frame for the requested media kind once.
    ///
    /// - Parameters:
    ///   - stage: First-frame stage that was observed.
    ///   - renderer: Renderer to detach after the event is emitted.
    func report(
        _ stage: ClientEventStage,
        renderer: MediaFrameReporter
    ) async {
        let tracksToDetach: ([RTCVideoTrack], [RTCAudioTrack])
        switch stage {
        case .firstVideoFrame:
            guard !didReportVideoFrame else { return }
            didReportVideoFrame = true
            tracksToDetach = (Array(videoTracks.values), [])
            videoTracks.removeAll()
        case .firstAudioFrame:
            guard !didReportAudioFrame else { return }
            didReportAudioFrame = true
            tracksToDetach = ([], Array(audioTracks.values))
            audioTracks.removeAll()
        default:
            return
        }

        tracksToDetach.0.forEach { $0.remove(renderer) }
        tracksToDetach.1.forEach { $0.remove(renderer) }

        // TODO: Attach track_id when the generated schema exposes it.
        await clientEventReporter.reportEvent(stage, details: details)
    }
}
