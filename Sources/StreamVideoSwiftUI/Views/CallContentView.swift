//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

struct CallContentView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    var viewModel: CallViewModel
    var bounds: CGRect

    @State var localVideoPrimary: Bool
    var localVideoPrimaryPublisher: AnyPublisher<Bool, Never>

    @State var screenSharingSession: ScreenSharingSession?
    var screenSharingSessionPublisher: AnyPublisher<ScreenSharingSession?, Never>?

    @State var isCurrentUserScreensharing: Bool
    var isCurrentUserScreensharingPublisher: AnyPublisher<Bool, Never>?

    @State var participantsLayout: ParticipantsLayout
    var participantsLayoutPublisher: AnyPublisher<ParticipantsLayout, Never>

    @State var callSettings: CallSettings
    var callSettingsPublisher: AnyPublisher<CallSettings, Never>

    init(
        viewFactory: Factory,
        viewModel: CallViewModel,
        bounds: CGRect
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.bounds = bounds

        localVideoPrimary = viewModel.localVideoPrimary
        localVideoPrimaryPublisher = viewModel
            .$localVideoPrimary
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        screenSharingSession = viewModel.call?.state.screenSharingSession
        screenSharingSessionPublisher = viewModel
            .call?
            .state
            .$screenSharingSession
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        isCurrentUserScreensharing = viewModel.call?.state.isCurrentUserScreensharing ?? false
        isCurrentUserScreensharingPublisher = viewModel
            .call?
            .state
            .$isCurrentUserScreensharing
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        participantsLayout = viewModel.participantsLayout
        participantsLayoutPublisher = viewModel
            .$participantsLayout
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        callSettings = viewModel.callSettings
        callSettingsPublisher = viewModel
            .$callSettings
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var body: some View {
        contentView
            .onReceive(localVideoPrimaryPublisher) { localVideoPrimary = $0 }
            .onReceive(screenSharingSessionPublisher) { screenSharingSession = $0 }
            .onReceive(isCurrentUserScreensharingPublisher) { isCurrentUserScreensharing = $0 }
            .onReceive(participantsLayoutPublisher) { participantsLayout = $0 }
            .onReceive(callSettingsPublisher) { callSettings = $0 }
            .debugViewRendering()
    }

    @ViewBuilder
    var contentView: some View {
        if
            localVideoPrimary,
            participantsLayout == .grid,
            let localParticipant = viewModel.localParticipant {
            localVideoView(participant: localParticipant)
        } else if
            let screenSharingSession = screenSharingSession,
            !isCurrentUserScreensharing {
            screenSharingView(screenSharingSession: screenSharingSession)
        } else {
            participantsView(in: bounds)
        }
    }

    @ViewBuilder
    private func localVideoView(
        participant: CallParticipant
    ) -> some View {
        LocalVideoView(
            viewFactory: viewFactory,
            participant: participant,
            callSettings: callSettings,
            call: viewModel.call,
            availableFrame: bounds
        )
        .modifier(
            viewFactory.makeLocalParticipantViewModifier(
                localParticipant: participant,
                callSettings: .init(get: { viewModel.callSettings }, set: { viewModel.callSettings = $0 }),
                call: viewModel.call
            )
        )
        .id(participant.sessionId)
        .accessibility(identifier: "localVideoView")
    }

    @ViewBuilder
    func screenSharingView(
        screenSharingSession: ScreenSharingSession
    ) -> some View {
        viewFactory.makeScreenSharingView(
            viewModel: viewModel,
            screensharingSession: screenSharingSession,
            availableFrame: bounds
        )
    }

    @ViewBuilder
    func participantsView(in bounds: CGRect) -> some View {
        viewFactory.makeVideoParticipantsView(
            viewModel: viewModel,
            availableFrame: bounds,
            onChangeTrackVisibility: { [weak viewModel] in
                viewModel?.changeTrackVisibility(for: $0, isVisible: $1)
            }
        )
    }
}
