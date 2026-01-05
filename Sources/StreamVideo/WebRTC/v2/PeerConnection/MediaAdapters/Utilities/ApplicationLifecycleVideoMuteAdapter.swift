//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An adapter that handles video muting based on the application's lifecycle events.
final class ApplicationLifecycleVideoMuteAdapter {

    /// Adapter for observing application state changes.
    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    /// The session ID associated with the current video call.
    private let sessionID: String

    /// Adapter for interacting with the SFU (Selective Forwarding Unit).
    private let sfuAdapter: SFUAdapter

    /// A container for managing disposables.
    private let disposableBag = DisposableBag()

    /// Initializes the adapter with the given session ID and SFU adapter.
    ///
    /// - Parameters:
    ///   - sessionID: The session ID for the video call.
    ///   - sfuAdapter: The adapter for SFU interactions.
    init(
        sessionID: String,
        sfuAdapter: SFUAdapter
    ) {
        self.sessionID = sessionID
        self.sfuAdapter = sfuAdapter
    }

    /// Updates the call settings and removes all disposables if video is off.
    ///
    /// - Parameter callSettings: The settings for the current call.
    func didUpdateCallSettings(_ callSettings: CallSettings) {
        guard !callSettings.videoOn, !disposableBag.isEmpty else {
            return
        }
        disposableBag.removeAll()
        log.debug("\(type(of: self)) is now deactivated.", subsystems: .webRTC)
    }

    /// Starts capturing video and sets up muting based on app state.
    ///
    /// It only applies when one of the following
    /// is true:
    /// - The device is running iOS 16 or lower.
    /// - ``AVCaptureSession.isMultitaskingCameraAccessSupported`` is `false`.
    ///
    /// - Parameter capturer: The video capturer.
    func didStartCapturing(with capturer: StreamVideoCapturing) async {
        guard await capturer.supportsBackgrounding() == false else {
            return
        }
        applicationStateAdapter
            .statePublisher
            .filter { $0 == .background }
            .log(.debug, subsystems: .webRTC) { "Application state changed to \($0) and we are going to mute the video track." }
            .sinkTask(storeIn: disposableBag) { [weak sfuAdapter, sessionID] _ in
                try await sfuAdapter?.updateTrackMuteState(
                    .video,
                    isMuted: true,
                    for: sessionID
                )
            }
            .store(in: disposableBag)

        applicationStateAdapter
            .statePublisher
            .filter { $0 == .foreground }
            .log(.debug, subsystems: .webRTC) { "Application state changed to \($0) and we are going to unmute the video track." }
            .sinkTask(storeIn: disposableBag) { [weak sfuAdapter, sessionID] _ in
                try await sfuAdapter?.updateTrackMuteState(
                    .video,
                    isMuted: false,
                    for: sessionID
                )
            }
            .store(in: disposableBag)

        log.debug("\(type(of: self)) is now activated.", subsystems: .webRTC)
    }
}
