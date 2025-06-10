//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying call controls such as video toggle, microphone toggle, and participants list button.
public struct CallControlsView: View, Equatable {

    // VideoIconView
    var hasVideoCapability: Bool
    var isVideoEnabled: Bool

    // MicrophoneIconView
    var hasAudioCapability: Bool
    var isAudioEnabled: Bool

    // ParticipantsListButton
    var showParticipantsList: Bool
    var participantsCount: Int
    var participantsShown: Binding<Bool>

    let viewModel: CallViewModel

    /// Initializes the call controls view with a view model.
    /// - Parameter viewModel: The view model for the call controls.
    public init(viewModel: CallViewModel) {
        let call = viewModel.call ?? viewModel.streamVideo.state.ringingCall
        let ownCapabilities = Set(call?.state.ownCapabilities ?? [])

        hasVideoCapability = ownCapabilities.contains(.sendVideo)
        isVideoEnabled = call?.state.callSettings.videoOn ?? false

        hasAudioCapability = ownCapabilities.contains(.sendAudio)
        isAudioEnabled = call?.state.callSettings.audioOn ?? false

        showParticipantsList = viewModel.callingState == .inCall
        participantsCount = call?.state.participants.endIndex ?? 0
        participantsShown = .init(get: { viewModel.participantsShown }, set: { viewModel.participantsShown = $0 })

        self.viewModel = viewModel
    }

    nonisolated public static func == (
        lhs: CallControlsView,
        rhs: CallControlsView
    ) -> Bool {
        lhs.hasVideoCapability == rhs.hasVideoCapability
            && lhs.isVideoEnabled == rhs.isVideoEnabled
            && lhs.hasAudioCapability == rhs.hasAudioCapability
            && lhs.isAudioEnabled == rhs.isAudioEnabled
            && lhs.showParticipantsList == rhs.showParticipantsList
            && lhs.participantsCount == rhs.participantsCount
            && lhs.participantsShown.wrappedValue == rhs.participantsShown.wrappedValue
    }

    public var body: some View {
        HStack {
            if hasVideoCapability {
                VideoIconView(
                    isEnabled: isVideoEnabled,
                    actionHandler: { [weak viewModel] in viewModel?.toggleCameraEnabled() }
                )
                .equatable()
            }
            if hasAudioCapability {
                MicrophoneIconView(
                    isEnabled: isAudioEnabled,
                    actionHandler: { [weak viewModel] in viewModel?.toggleMicrophoneEnabled() }
                )
                .equatable()
            }

            Spacer()

            if showParticipantsList {
                ParticipantsListButton(
                    count: participantsCount,
                    isActive: participantsShown,
                    actionHandler: { [weak viewModel] in viewModel?.participantsShown = true }
                )
                .equatable()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical)
        .frame(maxWidth: .infinity)
    }
}
