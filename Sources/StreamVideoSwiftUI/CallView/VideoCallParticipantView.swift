//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct VideoCallParticipantView<Factory: ViewFactory>: View, Equatable {
    private final class ViewModel: @unchecked Sendable {
        private let participant: CallParticipant
        private let call: Call?
        private let queue = UnfairQueue()
        private let disposableBag = DisposableBag()
        private var lastReportedSize: CGSize = .zero

        init(participant: CallParticipant, call: Call?) {
            self.participant = participant
            self.call = call
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

    var viewFactory: Factory
    var participant: CallParticipant
    var availableFrame: CGRect
    var contentMode: UIView.ContentMode
    var edgesIgnoringSafeArea: Edge.Set
    var showVideo: Bool
    var isLocalUser: Bool
    var isUsingFrontCameraForLocalUser: Bool = false

    private let viewModel: ViewModel

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
        showVideo = participant.shouldDisplayTrack || customData["videoOn"]?.boolValue == true
        isLocalUser = call?.state.localParticipant?.sessionId == participant.sessionId
        isUsingFrontCameraForLocalUser = call?.state.callSettings.cameraPosition == .front
        viewModel = .init(participant: participant, call: call)
    }

    var description: String {
        let components = [
            "VideoCallParticipantView with",
            "participant name:\(participant.name)",
            "sessionId:\(participant.sessionId)",
            "availableFrame:\(availableFrame)",
            "contentMode:\(contentMode)",
            "edgesIgnoringSafeArea:\(edgesIgnoringSafeArea)",
            "showVideo:\(showVideo)",
            "isLocalUser:\(isLocalUser)",
            "isUsingFrontCameraForLocalUser:\(isUsingFrontCameraForLocalUser)"
        ]
        return "<\(components.joined(separator: " "))/>"
    }

    nonisolated public static func == (
        lhs: VideoCallParticipantView<Factory>,
        rhs: VideoCallParticipantView<Factory>
    ) -> Bool {
        let result = lhs.participant.sessionId == rhs.participant.sessionId
            /// Show video isn't enough for localVideoUser as CustomData may be true when track is nil
            /// causing the view to not update when the track is loaded. For that reason we rely directl
            /// on the participant information regarding track visibility.
            && lhs.showVideo == rhs.showVideo
            && lhs.participant.shouldDisplayTrack == rhs.participant.shouldDisplayTrack
            && lhs.availableFrame == rhs.availableFrame
            && lhs.contentMode == rhs.contentMode
            && lhs.edgesIgnoringSafeArea == rhs.edgesIgnoringSafeArea
            && lhs.isLocalUser == rhs.isLocalUser
            && lhs.isUsingFrontCameraForLocalUser == rhs.isUsingFrontCameraForLocalUser

        log.debug("Comparing \(lhs) and \(rhs) result is \(result)")
        return result
    }

    public var body: some View {
        contentViewWithRotationAwareness
            .edgesIgnoringSafeArea(edgesIgnoringSafeArea)
            .accessibility(identifier: "callParticipantView")
            .streamAccessibility(value: showVideo ? "1" : "0")
    }

    @ViewBuilder
    private var participantInfoView: some View {
        CallParticipantImageView(
            viewFactory: viewFactory,
            id: participant.id,
            name: participant.name,
            imageURL: participant.profileImageURL
        )
        .frame(width: availableFrame.width, height: availableFrame.height)
    }

    @ViewBuilder
    private var contentViewWithRotationAwareness: some View {
        if isUsingFrontCameraForLocalUser, showVideo {
            contentView
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        } else {
            contentView
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if showVideo {
            VideoRendererView(
                id: participant.sessionId,
                size: availableFrame.size,
                contentMode: contentMode,
                showVideo: showVideo,
                handleRendering: { [weak viewModel] in viewModel?.handleViewRendering($0) }
            )
        } else {
            participantInfoView
        }
    }
}
