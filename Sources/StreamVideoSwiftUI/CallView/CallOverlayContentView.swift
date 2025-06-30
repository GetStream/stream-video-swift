//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

struct CallOverlayContentView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    var viewModel: CallViewModel
    var proxy: GeometryProxy

    @State var localVideoPrimary: Bool
    var localVideoPrimaryPublisher: AnyPublisher<Bool, Never>

    @State var screenSharingSession: ScreenSharingSession?
    var screenSharingSessionPublisher: AnyPublisher<ScreenSharingSession?, Never>?

    @State var isCurrentUserScreensharing: Bool
    var isCurrentUserScreensharingPublisher: AnyPublisher<Bool, Never>?

    @State var participantsLayout: ParticipantsLayout
    var participantsLayoutPublisher: AnyPublisher<ParticipantsLayout, Never>

    @State var participantsCount: Int
    var participantsCountPublisher: AnyPublisher<Int, Never>?

    @State var callSettings: CallSettings
    var callSettingsPublisher: AnyPublisher<CallSettings, Never>

    @State var hideUIElements: Bool
    var hideUIElementsPublisher: AnyPublisher<Bool, Never>

    init(
        viewFactory: Factory,
        viewModel: CallViewModel,
        proxy: GeometryProxy
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.proxy = proxy

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

        participantsCount = viewModel.call?.state.participants.endIndex ?? 0
        participantsCountPublisher = viewModel
            .call?
            .state
            .$participants
            .map(\.endIndex)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        callSettings = viewModel.callSettings
        callSettingsPublisher = viewModel
            .$callSettings
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        hideUIElements = viewModel.hideUIElements
        hideUIElementsPublisher = viewModel
            .$hideUIElements
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var isVisible: Bool {
        (screenSharingSession == nil || isCurrentUserScreensharing)
            && participantsLayout == .grid
            && participantsCount <= 3
            && !hideUIElements
    }

    var body: some View {
        contentView
            .onReceive(localVideoPrimaryPublisher) { localVideoPrimary = $0 }
            .onReceive(screenSharingSessionPublisher) { screenSharingSession = $0 }
            .onReceive(isCurrentUserScreensharingPublisher) { isCurrentUserScreensharing = $0 }
            .onReceive(participantsLayoutPublisher) { participantsLayout = $0 }
            .onReceive(participantsCountPublisher) { participantsCount = $0 }
            .onReceive(callSettingsPublisher) { callSettings = $0 }
            .onReceive(hideUIElementsPublisher) { hideUIElements = $0 }
    }

    @ViewBuilder
    var contentView: some View {
        if isVisible {
            CornerDraggableView(
                content: { overlayView(in: $0) },
                proxy: proxy,
                onTap: {
                    withAnimation {
                        if participantsCount == 2 {
                            viewModel.localVideoPrimary.toggle()
                        }
                    }
                }
            )
            .accessibility(identifier: "cornerDraggableView")
            .padding()
        }
    }

    @ViewBuilder
    func overlayView(in bounds: CGRect) -> some View {
        if localVideoPrimary {
            otherParticipantView(in: bounds)
        } else {
            localVideoView(in: bounds)
        }
    }

    @ViewBuilder
    func localVideoView(in overlayBounds: CGRect) -> some View {
        if let localParticipant = viewModel.localParticipant {
            LocalVideoView(
                viewFactory: viewFactory,
                participant: localParticipant,
                callSettings: callSettings,
                call: viewModel.call,
                availableFrame: overlayBounds
            )
            .modifier(
                viewFactory.makeLocalParticipantViewModifier(
                    localParticipant: localParticipant,
                    callSettings: .init(get: { viewModel.callSettings }, set: { viewModel.callSettings = $0 }),
                    call: viewModel.call
                )
            )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    func otherParticipantView(in overlayBounds: CGRect) -> some View {
        if let firstParticipant = viewModel.participants.first {
            viewFactory.makeVideoParticipantView(
                participant: firstParticipant,
                id: firstParticipant.id,
                availableFrame: overlayBounds,
                contentMode: .scaleAspectFill,
                customData: [:],
                call: viewModel.call
            )
            .modifier(
                viewFactory.makeVideoCallParticipantModifier(
                    participant: firstParticipant,
                    call: viewModel.call,
                    availableFrame: overlayBounds,
                    ratio: overlayBounds.width / overlayBounds.height,
                    showAllInfo: true
                )
            )
            .accessibility(identifier: "minimizedParticipantView")
        } else {
            EmptyView()
        }
    }
}
