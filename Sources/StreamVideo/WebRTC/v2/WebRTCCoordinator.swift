//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class WebRTCCoordinator: @unchecked Sendable {
    typealias AuthenticationHandler = (Bool, Bool, String?) async throws -> JoinCallResponse

    private static let recordingUserId = "recording-egress"
    private static let participantsThreshold = 10

    let stateAdapter: WebRTCStateAdapter
    let callAuthentication: AuthenticationHandler
    private(set) lazy var stateMachine: StateMachine = .init(.init(coordinator: self))

    private let disposableBag = DisposableBag()

    private var didUpdateParticipantsCancellable: AnyCancellable?

    init(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig,
        callAuthentication: @escaping AuthenticationHandler,
        rtcPeerConnectionCoordinatorFactory: RTCPeerConnectionCoordinatorProviding = StreamRTCPeerConnectionCoordinatorFactory()
    ) {
        stateAdapter = .init(
            user: user,
            apiKey: apiKey,
            callCid: callCid,
            videoConfig: videoConfig,
            rtcPeerConnectionCoordinatorFactory: rtcPeerConnectionCoordinatorFactory
        )
        self.callAuthentication = callAuthentication

        _ = stateMachine

        stateMachine
            .publisher
            .sink { [weak self] in self?.didTransition(to: $0.id) }
            .store(in: disposableBag)

        observeForceReconnectionRequests()
    }

    // MARK: - Connection

    func connect(
        callSettings: CallSettings?,
        ring: Bool
    ) async throws {
        await stateAdapter.set(initialCallSettings: callSettings)
        try stateMachine.transition(
            .connecting(stateMachine.currentStage.context, ring: ring)
        )
    }

    func cleanUp() async {
        await stateAdapter.cleanUp()
    }

    func leave() {
        do {
            try stateMachine.transition(
                .leaving(stateMachine.currentStage.context)
            )
        } catch {
            log.error(error, subsystems: .webRTC)
        }
    }

    // MARK: - Media

    func changeCameraMode(
        position: CameraPosition
    ) async throws {
        await stateAdapter.set(
            stateAdapter
                .callSettings
                .withUpdatedCameraPosition(position)
        )
        try await stateAdapter.publisher?.didUpdateCameraPosition(
            position == .front ? .front : .back
        )
    }

    func changeAudioState(isEnabled: Bool) async {
        await stateAdapter.set(
            stateAdapter
                .callSettings
                .withUpdatedAudioState(isEnabled)
        )
    }

    func changeVideoState(isEnabled: Bool) async {
        await stateAdapter.set(
            stateAdapter
                .callSettings
                .withUpdatedVideoState(isEnabled)
        )
    }

    func changeSoundState(isEnabled: Bool) async {
        await stateAdapter.set(
            stateAdapter
                .callSettings
                .withUpdatedAudioOutputState(isEnabled)
        )
    }

    func changeSpeakerState(isEnabled: Bool) async {
        await stateAdapter.set(
            stateAdapter
                .callSettings
                .withUpdatedSpeakerState(isEnabled)
        )
    }

    func changeTrackVisibility(
        for participant: CallParticipant,
        isVisible: Bool
    ) async {
        await stateAdapter
            .didUpdateParticipant(participant, isVisible: isVisible)
    }

    func updateTrackSize(
        _ trackSize: CGSize,
        for participant: CallParticipant
    ) async {
        await stateAdapter.didUpdateParticipant(
            participant,
            trackSize: trackSize
        )
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) async {
        await stateAdapter.set(videoFilter)
    }

    func startScreensharing(
        type: ScreensharingType
    ) async throws {
        try await stateAdapter.publisher?.beginScreenSharing(
            of: type,
            ownCapabilities: Array(stateAdapter.ownCapabilities)
        )
    }

    func stopScreensharing() async throws {
        try await stateAdapter.publisher?.stopScreenSharing()
    }

    func changePinState(
        isEnabled: Bool,
        sessionId: String
    ) async throws {
        var participants = await stateAdapter.participants

        guard
            let participant = participants[sessionId]
        else {
            throw ClientError.Unexpected()
        }

        participants[sessionId] = participant.withUpdated(
            pin: isEnabled
                ? PinInfo(isLocal: true, pinnedAt: Date())
                : nil
        )

        await stateAdapter.didUpdateParticipants(participants)
    }

    func startNoiseCancellation(
        _ sessionID: String
    ) async throws {
        try await stateAdapter
            .sfuAdapter?
            .toggleNoiseCancellation(true, for: sessionID)
    }

    func stopNoiseCancellation(
        _ sessionID: String
    ) async throws {
        try await stateAdapter
            .sfuAdapter?
            .toggleNoiseCancellation(false, for: sessionID)
    }

    func focus(at point: CGPoint) async throws {
        try await stateAdapter.publisher?.focus(at: point)
    }

    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        try await stateAdapter
            .publisher?
            .addCapturePhotoOutput(capturePhotoOutput)
    }

    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        try await stateAdapter
            .publisher?
            .removeCapturePhotoOutput(capturePhotoOutput)
    }

    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        try await stateAdapter
            .publisher?
            .addVideoOutput(videoOutput)
    }

    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        try await stateAdapter
            .publisher?
            .removeVideoOutput(videoOutput)
    }

    func zoom(by factor: CGFloat) async throws {
        try await stateAdapter
            .publisher?
            .zoom(by: factor)
    }

    // MARK: - SFU Events Handling

    // MARK: - Private

    private func makeStateMachine() async -> WebRTCCoordinator.StateMachine {
        .init(.init(coordinator: self))
    }

    private func didTransition(
        to stageId: StateMachine.Stage.ID
    ) {
        switch stageId {
        default:
            break
        }
    }

    private func observeForceReconnectionRequests() {
        NotificationCenter
            .default
            .publisher(for: .init("video.getstream.io.reconnect.fast"))
            .sink { [weak self] _ in
                guard let self else { return }
                stateMachine.currentStage.context.reconnectionStrategy = .fast(
                    disconnectedSince: .init(),
                    deadline: stateMachine.currentStage.context.fastReconnectDeadlineSeconds
                )
                do {
                    try stateMachine.transition(
                        .disconnected(stateMachine.currentStage.context)
                    )
                } catch {
                    log.error(error, subsystems: .webRTC)
                }
            }
            .store(in: disposableBag)

        NotificationCenter
            .default
            .publisher(for: .init("video.getstream.io.reconnect.rejoin"))
            .sink { [weak self] _ in
                guard let self else { return }
                stateMachine.currentStage.context.reconnectionStrategy = .rejoin
                do {
                    try stateMachine.transition(
                        .disconnected(stateMachine.currentStage.context)
                    )
                } catch {
                    log.error(error, subsystems: .webRTC)
                }
            }
            .store(in: disposableBag)

        NotificationCenter
            .default
            .publisher(for: .init("video.getstream.io.reconnect.migrate"))
            .sink { [weak self] _ in
                guard let self else { return }
                stateMachine.currentStage.context.reconnectionStrategy = .migrate
                do {
                    try stateMachine.transition(
                        .disconnected(stateMachine.currentStage.context)
                    )
                } catch {
                    log.error(error, subsystems: .webRTC)
                }
            }
            .store(in: disposableBag)
    }
}

extension Published.Publisher: @unchecked Sendable {}
extension RTCMediaStreamTrack: @unchecked Sendable {}
extension AudioSettings: @unchecked Sendable {}
