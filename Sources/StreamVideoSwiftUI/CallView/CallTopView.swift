//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallTopView: View, @preconcurrency Equatable {
    // LayoutMenuView
    var participantsCount: Int
    var isAnotherUserScreenSharing: Bool
    var participantsLayout: ParticipantsLayout

    // ToggleCameraIconView
    var hasVideoCapability: Bool
    var cameraPosition: CameraPosition

    // CallDurationView
    var recordingState: RecordingState

    // SharingIndicator
    var isCurrentUserScreenSharing: Bool
    @State var sharingPopupDismissed = false

    private let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        let streamVideo = viewModel.streamVideo
        let call = viewModel.call ?? streamVideo.state.ringingCall

        // LayoutMenu
        participantsCount = viewModel.callParticipants.count
        isAnotherUserScreenSharing = viewModel.call?.state.isCurrentUserScreensharing == false
            && viewModel.call?.state.screenSharingSession != nil
        participantsLayout = viewModel.participantsLayout

        // ToggleCameraIconView
        hasVideoCapability = call?.state.ownCapabilities.contains(.sendVideo) == true
        cameraPosition = call?.state.callSettings.cameraPosition ?? .front

        // CallDurationView
        recordingState = viewModel.recordingState

        // SharingIndicator
        isCurrentUserScreenSharing = viewModel.call?.state.isCurrentUserScreensharing ?? false

        self.viewModel = viewModel
    }

    public static func == (
        lhs: CallTopView,
        rhs: CallTopView
    ) -> Bool {
        lhs.participantsCount == rhs.participantsCount
            && lhs.isAnotherUserScreenSharing == rhs.isAnotherUserScreenSharing
            && lhs.participantsLayout == rhs.participantsLayout
            && lhs.hasVideoCapability == rhs.hasVideoCapability
            && lhs.cameraPosition == rhs.cameraPosition
            && lhs.recordingState == rhs.recordingState
            && lhs.isCurrentUserScreenSharing == rhs.isCurrentUserScreenSharing
            && lhs.sharingPopupDismissed == rhs.sharingPopupDismissed
    }

    public var body: some View {
        Group {
            HStack(spacing: 0) {
                HStack {
                    layoutMenuView
                    toggleCameraView
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                HStack(alignment: .center) {
                    callDurationView
                }
                .frame(height: 44)
                .frame(maxWidth: .infinity)

                HStack {
                    Spacer()
                    hangUpIconView
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
        }
        .overlay(sharingIndicatorView)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var layoutMenuView: some View {
        if
            #available(iOS 14.0, *),
            participantsCount > 1,
            !isAnotherUserScreenSharing
        {
            LayoutMenuView(
                participantsLayout: participantsLayout,
                actionHandler: { [weak viewModel] in viewModel?.update(participantsLayout: $0) }
            )
            .equatable()
            .accessibility(identifier: "viewMenu")
        }
    }

    @ViewBuilder
    private var toggleCameraView: some View {
        if hasVideoCapability {
            ToggleCameraIconView(
                cameraPosition: cameraPosition,
                actionHandler: { [weak viewModel] in viewModel?.toggleCameraPosition() }
            )
            .equatable()
        }
    }

    @ViewBuilder
    private var callDurationView: some View {
        CallDurationView(viewModel).equatable()
    }

    @ViewBuilder
    private var hangUpIconView: some View {
        HangUpIconView(viewModel: viewModel)
            .equatable()
    }

    @ViewBuilder
    private var sharingIndicatorView: some View {
        if isCurrentUserScreenSharing {
            SharingIndicator(
                viewModel: viewModel,
                sharingPopupDismissed: $sharingPopupDismissed,
            )
            .equatable()
            .opacity(sharingPopupDismissed ? 0 : 1)
        }
    }
}
