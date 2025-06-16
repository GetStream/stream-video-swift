//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamWebRTC
import SwiftUI

public struct VideoCallParticipantView<Factory: ViewFactory>: View {
    var viewFactory: Factory
    var participant: CallParticipant
    var availableFrame: CGRect
    var contentMode: UIView.ContentMode
    var edgesIgnoringSafeArea: Edge.Set
    var customData: [String: RawJSON]
    var call: Call?

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        participant: CallParticipant,
        id: String? = nil,
        availableFrame: CGRect,
        contentMode: UIView.ContentMode,
        edgesIgnoringSafeArea: Edge.Set = .all,
        customData: [String: RawJSON],
        call: Call?
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.availableFrame = availableFrame
        self.contentMode = contentMode
        self.edgesIgnoringSafeArea = edgesIgnoringSafeArea
        self.customData = customData
        self.call = call
    }

    public var body: some View {
        if #available(iOS 14.0, *) {
            VideoCallParticipantContentView(
                viewFactory: viewFactory,
                participant: participant,
                availableFrame: availableFrame,
                contentMode: contentMode,
                edgesIgnoringSafeArea: edgesIgnoringSafeArea,
                customData: customData,
                call: call
            )
            .id(participant.sessionId)
        } else {
            VideoCallParticipantContentView_iOS13(
                viewFactory: viewFactory,
                participant: participant,
                availableFrame: availableFrame,
                contentMode: contentMode,
                edgesIgnoringSafeArea: edgesIgnoringSafeArea,
                customData: customData,
                call: call
            )
            .id(participant.sessionId)
        }
    }
}

extension VideoCallParticipantView {
    private final class ViewModel: ObservableObject, @unchecked Sendable {
        let participant: CallParticipant
        let isLocalUser: Bool

        private let call: Call?
        private let queue = UnfairQueue()
        private let disposableBag = DisposableBag()
        private var lastReportedSize: CGSize = .zero

        @Published private(set) var track: RTCVideoTrack?
        @Published private(set) var showVideo: Bool
        @Published var isUsingFrontCameraForLocalUser: Bool

        @MainActor
        init(
            participant: CallParticipant,
            call: Call?,
            customData: [String: RawJSON]
        ) {
            self.call = call
            self.participant = participant
            isLocalUser = participant.sessionId == call?.state.localParticipant?.sessionId
            isUsingFrontCameraForLocalUser = call?.state.callSettings.cameraPosition == .front

            showVideo = participant.shouldDisplayTrack || customData["videoOn"]?.boolValue == true

            call?
                .state
                .$participants
                .receive(on: DispatchQueue.global(qos: .background))
                .compactMap { participants in participants.first(where: { $0.sessionId == participant.sessionId }) }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.didUpdate($0) }
                .store(in: disposableBag)
        }

        private func didUpdate(_ participant: CallParticipant) {
            if participant.shouldDisplayTrack != showVideo {
                showVideo = participant.shouldDisplayTrack
            }

            if participant.track?.trackId != track?.trackId {
                track = participant.track
            }
        }

        @MainActor
        func handleViewRendering(_ renderer: VideoRenderer) {
            guard call != nil else {
                return
            }
            renderer.handleViewRendering(for: participant) { [weak self] size, participant in
                self?.didRender(size: size, participant: participant)
            }
        }

        func didRender(size: CGSize, participant: CallParticipant) {
            guard
                let call,
                queue.sync({ lastReportedSize }) != size,
                participant.sessionId == self.participant.sessionId
            else {
                return
            }

            log.debug("Will update participant:\(participant.name) trackSize:\(size).")
            Task(disposableBag: disposableBag) { [weak call] in
                await call?.updateTrackSize(size, for: participant)
            }

            queue.sync { lastReportedSize = size }
        }
    }

    @available(iOS 14.0, *)
    private struct VideoCallParticipantContentView: View {
        var viewFactory: Factory
        var availableFrame: CGRect
        var contentMode: UIView.ContentMode
        var edgesIgnoringSafeArea: Edge.Set

        @StateObject private var viewModel: ViewModel

        init(
            viewFactory: Factory,
            participant: CallParticipant,
            availableFrame: CGRect,
            contentMode: UIView.ContentMode,
            edgesIgnoringSafeArea: Edge.Set,
            customData: [String: RawJSON],
            call: Call?
        ) {
            self.viewFactory = viewFactory
            self.availableFrame = availableFrame
            self.contentMode = contentMode
            self.edgesIgnoringSafeArea = edgesIgnoringSafeArea
            _viewModel = .init(
                wrappedValue: .init(
                    participant: participant,
                    call: call,
                    customData: customData
                )
            )
        }

        public var body: some View {
            contentViewWithRotationAwareness
                .edgesIgnoringSafeArea(edgesIgnoringSafeArea)
                .accessibility(identifier: "callParticipantView")
                .streamAccessibility(value: viewModel.showVideo ? "1" : "0")
        }

        @ViewBuilder
        private var participantInfoView: some View {
            CallParticipantImageView(
                viewFactory: viewFactory,
                id: viewModel.participant.id,
                name: viewModel.participant.name,
                imageURL: viewModel.participant.profileImageURL
            )
            .frame(width: availableFrame.width, height: availableFrame.height)
        }

        @ViewBuilder
        private var contentViewWithRotationAwareness: some View {
            if viewModel.isLocalUser, viewModel.isUsingFrontCameraForLocalUser, viewModel.showVideo {
                contentView
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                contentView
            }
        }

        @ViewBuilder
        private var contentView: some View {
            if viewModel.showVideo, let track = viewModel.track {
                TrackVideoRendererView(
                    track: track
                ) { viewModel.didRender(size: $0, participant: viewModel.participant) }
                    .equatable()
                    .frame(width: availableFrame.width, height: availableFrame.height)
                    .fixedSize()
            } else {
                participantInfoView
            }
        }

        @ViewBuilder
        private var legacyContentView: some View {
            if viewModel.showVideo {
                VideoRendererView(
                    id: viewModel.participant.sessionId,
                    size: availableFrame.size,
                    contentMode: contentMode,
                    showVideo: viewModel.showVideo,
                    handleRendering: { [weak viewModel] in viewModel?.handleViewRendering($0) }
                )
            } else {
                participantInfoView
            }
        }
    }

    @available(iOS, introduced: 13, obsoleted: 14)
    private struct VideoCallParticipantContentView_iOS13: View {
        var viewFactory: Factory
        var availableFrame: CGRect
        var contentMode: UIView.ContentMode
        var edgesIgnoringSafeArea: Edge.Set

        @BackportStateObject private var viewModel: ViewModel

        init(
            viewFactory: Factory,
            participant: CallParticipant,
            availableFrame: CGRect,
            contentMode: UIView.ContentMode,
            edgesIgnoringSafeArea: Edge.Set,
            customData: [String: RawJSON],
            call: Call?
        ) {
            self.viewFactory = viewFactory
            self.availableFrame = availableFrame
            self.contentMode = contentMode
            self.edgesIgnoringSafeArea = edgesIgnoringSafeArea
            _viewModel = .init(
                wrappedValue: .init(
                    participant: participant,
                    call: call,
                    customData: customData
                )
            )
        }

        public var body: some View {
            contentViewWithRotationAwareness
                .edgesIgnoringSafeArea(edgesIgnoringSafeArea)
                .accessibility(identifier: "callParticipantView")
                .streamAccessibility(value: viewModel.showVideo ? "1" : "0")
        }

        @ViewBuilder
        private var participantInfoView: some View {
            CallParticipantImageView(
                viewFactory: viewFactory,
                id: viewModel.participant.id,
                name: viewModel.participant.name,
                imageURL: viewModel.participant.profileImageURL
            )
            .frame(width: availableFrame.width, height: availableFrame.height)
        }

        @ViewBuilder
        private var contentViewWithRotationAwareness: some View {
            if viewModel.isLocalUser, viewModel.isUsingFrontCameraForLocalUser, viewModel.showVideo {
                contentView
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                contentView
            }
        }

        @ViewBuilder
        private var contentView: some View {
            if viewModel.showVideo, let track = viewModel.participant.track {
                TrackVideoRendererView(
                    track: track
                ) { viewModel.didRender(size: $0, participant: viewModel.participant) }
                    .equatable()
                    .frame(width: availableFrame.width, height: availableFrame.height)
                    .fixedSize()
            } else {
                participantInfoView
            }
        }

        @ViewBuilder
        private var legacyContentView: some View {
            if viewModel.showVideo {
                VideoRendererView(
                    id: viewModel.participant.sessionId,
                    size: availableFrame.size,
                    contentMode: contentMode,
                    showVideo: viewModel.showVideo,
                    handleRendering: { [weak viewModel] in viewModel?.handleViewRendering($0) }
                )
            } else {
                participantInfoView
            }
        }
    }
}
