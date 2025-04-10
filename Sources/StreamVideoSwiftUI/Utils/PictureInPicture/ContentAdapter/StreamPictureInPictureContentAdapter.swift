//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC

final class StreamPictureInPictureContentAdapter: @unchecked Sendable {

    var isActive: Bool = false {
        willSet {
            if newValue == false {
                disposableBag.removeAll()
                dataPipeline.send(.none)
            } else if newValue, let call {
                subscribeToDataPipeline()
                subscribeToCallUpdates(on: call)
                log.debug("Picture-in-Picture content broadcasting started.", subsystems: .pictureInPicture)
            } else {
                /* No-op */
            }
        }
    }

    var call: Call? {
        didSet { didUpdate(call, oldValue: oldValue) }
    }

    private let dataPipeline: PictureInPictureDataPipeline
    private let trackStateAdapter: StreamPictureInPictureTrackStateAdapter = .init()
    private let disposableBag: DisposableBag = .init()
    private lazy var contentProviders: [StreamPictureInPictureContentProvider] = [
        StreamPictureInPictureParticipantContentProvider(dataPipeline: dataPipeline),
        StreamPictureInPictureScreenSharingContentProvider(dataPipeline: dataPipeline),
        StreamPictureInPictureStaticContentProvider(dataPipeline: dataPipeline),
        StreamPictureInPictureReconnectingContentProvider(dataPipeline: dataPipeline)
    ]

    init(dataPipeline: PictureInPictureDataPipeline) {
        self.dataPipeline = dataPipeline
    }

    // MARK: - Updaters

    private func didUpdate(_ call: Call?, oldValue: Call?) {
        disposableBag.removeAll()
        dataPipeline.send(.none)
        contentProviders.forEach {
            var provider = $0
            provider.call = call
        }
    }

    @MainActor
    private func didUpdate(_ participants: [CallParticipant]) {
        guard let call else {
            return
        }
        let sessionId = call.state.sessionId
        let otherParticipants = participants.filter { $0.sessionId != sessionId }

        if
            let session = call.state.screenSharingSession,
            call.state.isCurrentUserScreensharing == false,
            let track = session.track {
            dataPipeline.send(.screenSharing(session.participant, track: track))
        } else if
            let participant = otherParticipants.first(where: { $0.isDominantSpeaker }) {
            if participant.hasVideo, let track = participant.track {
                dataPipeline.send(.participant(participant, track: track))
            } else {
                dataPipeline.send(.static(participant))
            }
        } else if
            let participant = otherParticipants.first(where: { $0.hasVideo && $0.track != nil }),
            let track = participant.track {
            dataPipeline.send(.participant(participant, track: track))
        } else if
            let localParticipant = call.state.localParticipant,
            localParticipant.hasVideo,
            let track = localParticipant.track {
            dataPipeline.send(.participant(localParticipant, track: track))
        } else if let participant = participants.first {
            dataPipeline.send(.static(participant))
        } else {
            dataPipeline.send(.none)
        }
    }

    // MARK: - Subscriptions

    private func subscribeToDataPipeline() {
        dataPipeline
            .contentPublisher
            .removeDuplicates()
            .sink { [weak self] in self?.process($0) }
            .store(in: disposableBag)
    }

    private func subscribeToCallUpdates(on call: Call) {
        Task { @MainActor in
            call
                .state
                .$participants
                .receive(on: DispatchQueue.main)
                .removeDuplicates()
                .sinkTask { @MainActor [weak self] in self?.didUpdate($0) }
                .store(in: disposableBag)

            call
                .state
                .$reconnectionStatus
                .filter { $0 != .connected }
                .removeDuplicates()
                .sink { [weak self] _ in self?.dataPipeline.send(.reconnecting) }
                .store(in: disposableBag)
        }
        .store(in: disposableBag)
    }

    // MARK: - Private Helpers

    private func process(_ content: PictureInPictureDataPipeline.Content) {
        contentProviders.forEach { $0.process(content) }

        switch content {
        case .none:
            trackStateAdapter.activeTrack = nil
            trackStateAdapter.isEnabled = false

        case let .participant(_, track), let .screenSharing(_, track):
            trackStateAdapter.activeTrack = track
            trackStateAdapter.isEnabled = true

        case .static, .reconnecting:
            trackStateAdapter.activeTrack = nil
            trackStateAdapter.isEnabled = true
        }
    }
}
