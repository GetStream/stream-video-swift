//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreGraphics
import Foundation
import StreamWebRTC

/// Reports the first rendered remote audio and video frames for a join attempt.
///
/// The reporter registers retained per-track renderers on remote RTC media
/// tracks and removes them after the first frame of each media kind is observed.
final class MediaFrameReporter: @unchecked Sendable {
    /// Stores renderer state behind actor isolation.
    private let storage: MediaFrameReporterStorage

    /// Creates a reporter that emits client events through the supplied reporter.
    /// - Parameter clientEventReporter: Reporter used for client-event delivery.
    init(clientEventReporter: ClientEventReporting) {
        storage = .init(clientEventReporter: clientEventReporter)
    }

    /// Starts a fresh reporting window for a new join attempt.
    /// - Parameter details: Event details attached to frame reports.
    func reset(details: ClientEventStageDetails) async {
        await storage.reset(details: details)
    }

    /// Registers a retained renderer on a remote media track when still needed.
    /// - Parameters:
    ///   - track: Track to observe for rendered frames.
    ///   - type: Media kind represented by the track.
    func add(_ track: RTCMediaStreamTrack, type: TrackType) async {
        await storage.add(track, type: type, reporter: self)
    }

    /// Removes the retained renderer from a previously observed track.
    /// - Parameters:
    ///   - track: Track that no longer needs frame observation.
    ///   - type: Media kind represented by the track.
    func remove(_ track: RTCMediaStreamTrack, type: TrackType) async {
        await storage.remove(track, type: type)
    }

    /// Removes this reporter from all currently observed tracks.
    func removeAllTracks() async {
        await storage.removeAllTracks()
    }

    /// Reports the first rendered frame from a retained track renderer.
    ///
    /// - Parameters:
    ///   - type: Media kind that produced the frame.
    ///   - trackId: Track id attached to the rendered frame event.
    func reportFrame(type: TrackType, trackId: String) async {
        await storage.report(type, trackId: trackId)
    }
}

/// Renderer retained per observed media track so frame reports carry track id.
final class MediaFrameTrackRenderer:
    NSObject,
    @unchecked Sendable,
    RTCVideoRenderer,
    RTCAudioRenderer {
    /// Reporter that receives forwarded frame callbacks.
    private weak var reporter: MediaFrameReporter?
    /// Media kind represented by the retained renderer.
    private let type: TrackType
    /// Track id attached to frame reports.
    private let trackId: String

    /// Creates a renderer for a single remote media track.
    ///
    /// - Parameters:
    ///   - type: Media kind represented by the track.
    ///   - trackId: Track id attached to frame reports.
    ///   - reporter: Reporter receiving first-frame notifications.
    init(type: TrackType, trackId: String, reporter: MediaFrameReporter) {
        self.type = type
        self.trackId = trackId
        self.reporter = reporter
    }

    /// Receives video-size updates required by ``RTCVideoRenderer``.
    func setSize(_ size: CGSize) {}

    /// Forwards rendered remote video frames to ``MediaFrameReporter``.
    ///
    /// - Parameter frame: Rendered frame supplied by WebRTC.
    func renderFrame(_ frame: RTCVideoFrame?) {
        guard frame != nil else { return }
        Task { [reporter, type, trackId] in
            await reporter?.reportFrame(type: type, trackId: trackId)
        }
    }

    /// Forwards rendered remote audio frames to ``MediaFrameReporter``.
    ///
    /// - Parameter pcmBuffer: Rendered audio buffer supplied by WebRTC.
    func render(pcmBuffer: AVAudioPCMBuffer) {
        Task { [reporter, type, trackId] in
            await reporter?.reportFrame(type: type, trackId: trackId)
        }
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
    private var videoTracks: [
        ObjectIdentifier: (track: RTCVideoTrack, renderer: MediaFrameTrackRenderer)
    ] = [:]
    /// Remote audio tracks currently observed for first-frame delivery.
    private var audioTracks: [
        ObjectIdentifier: (track: RTCAudioTrack, renderer: MediaFrameTrackRenderer)
    ] = [:]

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
    func reset(details: ClientEventStageDetails) {
        removeAllTracks()
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
    ///   - reporter: Reporter receiving retained renderer callbacks.
    func add(
        _ track: RTCMediaStreamTrack,
        type: TrackType,
        reporter: MediaFrameReporter
    ) {
        switch type {
        case .audio:
            guard let track = track as? RTCAudioTrack, !didReportAudioFrame else { return }
            let id = ObjectIdentifier(track)
            guard audioTracks[id] == nil else { return }
            let trackRenderer = MediaFrameTrackRenderer(
                type: type,
                trackId: track.trackId,
                reporter: reporter
            )
            audioTracks[id] = (track, trackRenderer)
            track.add(trackRenderer)
        case .video, .screenshare:
            guard let track = track as? RTCVideoTrack, !didReportVideoFrame else { return }
            let id = ObjectIdentifier(track)
            guard videoTracks[id] == nil else { return }
            let trackRenderer = MediaFrameTrackRenderer(
                type: type,
                trackId: track.trackId,
                reporter: reporter
            )
            videoTracks[id] = (track, trackRenderer)
            track.add(trackRenderer)
        default:
            return
        }
    }

    /// Detaches the renderer from a track that is no longer active.
    ///
    /// - Parameters:
    ///   - track: Remote media track to stop observing.
    ///   - type: Media kind represented by the track.
    func remove(_ track: RTCMediaStreamTrack, type: TrackType) {
        switch type {
        case .audio:
            guard let track = track as? RTCAudioTrack else { return }
            if let removed = audioTracks.removeValue(forKey: ObjectIdentifier(track)) {
                removed.track.remove(removed.renderer)
            }
        case .video, .screenshare:
            guard let track = track as? RTCVideoTrack else { return }
            if let removed = videoTracks.removeValue(forKey: ObjectIdentifier(track)) {
                removed.track.remove(removed.renderer)
            }
        default:
            return
        }
    }

    /// Detaches the renderer from all observed tracks.
    func removeAllTracks() {
        let videoTracksToDetach = Array(videoTracks.values)
        let audioTracksToDetach = Array(audioTracks.values)
        videoTracks.removeAll()
        audioTracks.removeAll()
        videoTracksToDetach.forEach { $0.track.remove($0.renderer) }
        audioTracksToDetach.forEach { $0.track.remove($0.renderer) }
    }

    /// Reports the first frame for the requested media kind once.
    ///
    /// - Parameters:
    ///   - type: Media kind that produced the frame.
    ///   - trackId: Track id attached to the frame event.
    func report(
        _ type: TrackType,
        trackId: String
    ) async {
        let stage: ClientEventStage
        let tracksToDetach: (
            [(
                track: RTCVideoTrack,
                renderer: MediaFrameTrackRenderer
            )],
            [(
                track: RTCAudioTrack,
                renderer: MediaFrameTrackRenderer
            )]
        )
        switch type {
        case .video, .screenshare:
            guard !didReportVideoFrame else { return }
            didReportVideoFrame = true
            stage = .firstVideoFrame
            tracksToDetach = (Array(videoTracks.values), [])
            videoTracks.removeAll()
        case .audio:
            guard !didReportAudioFrame else { return }
            didReportAudioFrame = true
            stage = .firstAudioFrame
            tracksToDetach = ([], Array(audioTracks.values))
            audioTracks.removeAll()
        default:
            return
        }

        tracksToDetach.0.forEach { $0.track.remove($0.renderer) }
        tracksToDetach.1.forEach { $0.track.remove($0.renderer) }

        await clientEventReporter.reportEvent(
            stage,
            details: details.merging(.init(trackId: trackId))
        )
    }
}
