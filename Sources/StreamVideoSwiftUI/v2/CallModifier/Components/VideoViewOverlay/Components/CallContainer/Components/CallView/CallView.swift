//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamWebRTC
import SwiftUI

public struct CallView<Factory: ViewFactory>: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors

    var viewFactory: Factory
    var viewModel: CallViewModel

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            headerView

            centerView

            footerView
        }
        .background(Color(colors.callBackground).edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var headerView: some View {
        viewFactory
            .makeCallTopView(viewModel: viewModel)
    }

    @ViewBuilder
    private var centerView: some View {
        CallContentView(
            viewFactory: viewFactory,
            viewModel: viewModel
        )
        .enablePictureInPicture(viewModel.isPictureInPictureEnabled)
    }

    @ViewBuilder
    private var footerView: some View {
        viewFactory.makeCallControlsView(viewModel: viewModel)
            .opacity(viewModel.hideUIElements ? 0 : 1)
            .presentParticipantListView(viewModel: viewModel, viewFactory: viewFactory)
    }
}

struct CallContentView<Factory: ViewFactory>: View {

    final class ViewModel: ObservableObject {
        @Published private(set) var localVideoPrimary: Bool
        @Published private(set) var participantsLayout: ParticipantsLayout
        @Published private(set) var screenSharingSession: ScreenSharingSession?
        @Published private(set) var isCurrentUserScreensharing: Bool
        @Published private(set) var participantsCount: Int
        @Published private(set) var hideUIElements: Bool

        @MainActor
        var localParticipant: CallParticipant? { callViewModel.localParticipant }

        let callViewModel: CallViewModel
        private let disposableBag = DisposableBag()

        @MainActor
        init(_ callViewModel: CallViewModel) {
            self.callViewModel = callViewModel
            localVideoPrimary = callViewModel.localVideoPrimary
            participantsLayout = callViewModel.participantsLayout
            screenSharingSession = callViewModel.call?.state.screenSharingSession
            isCurrentUserScreensharing = callViewModel.call?.state.isCurrentUserScreensharing ?? false
            participantsCount = callViewModel.callParticipants.count
            hideUIElements = callViewModel.hideUIElements

            callViewModel
                .$localVideoPrimary
                .removeDuplicates()
                .assign(to: \.localVideoPrimary, onWeak: self)
                .store(in: disposableBag)

            callViewModel
                .$participantsLayout
                .removeDuplicates()
                .assign(to: \.participantsLayout, onWeak: self)
                .store(in: disposableBag)

            callViewModel
                .$callParticipants
                .map(\.count)
                .removeDuplicates()
                .assign(to: \.participantsCount, onWeak: self)
                .store(in: disposableBag)

            callViewModel
                .$hideUIElements
                .removeDuplicates()
                .assign(to: \.hideUIElements, onWeak: self)
                .store(in: disposableBag)

            callViewModel
                .call?
                .state
                .$screenSharingSession
                .removeDuplicates(by: { $0?.participant.sessionId == $1?.participant.sessionId })
                .assign(to: \.screenSharingSession, onWeak: self)
                .store(in: disposableBag)

            callViewModel
                .call?
                .state
                .$isCurrentUserScreensharing
                .removeDuplicates()
                .assign(to: \.isCurrentUserScreensharing, onWeak: self)
                .store(in: disposableBag)
        }
    }

    var viewFactory: Factory
    @ObservedObject var viewModel: ViewModel

    init(
        viewFactory: Factory,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        _viewModel = .init(initialValue: .init(viewModel))
    }

    var body: some View {
        GeometryReader { proxy in
            Group {
                if viewModel.localVideoPrimary, let participant = viewModel.localParticipant {
                    makeLocalVideoCallParticipantView(
                        participant,
                        in: proxy.frame(in: .global)
                    )
                } else if let screenSharingSession = viewModel.screenSharingSession, !viewModel.isCurrentUserScreensharing {
                    viewFactory.makeScreenSharingView(
                        viewModel: viewModel.callViewModel,
                        screensharingSession: screenSharingSession,
                        availableFrame: proxy.frame(in: .global)
                    )
                } else {
                    viewFactory.makeVideoParticipantsView(
                        viewModel: viewModel.callViewModel,
                        availableFrame: proxy.frame(in: .global),
                        onChangeTrackVisibility: { [weak viewModel] in
                            viewModel?.callViewModel.changeTrackVisibility(for: $0, isVisible: $1)
                        }
                    )
                }
            }
            .overlay(makeOverlayViewIfRequired(proxy))
            .padding([.leading, .trailing], 8)
        }
    }

    @ViewBuilder
    private func makeLocalVideoCallParticipantView(
        _ participant: CallParticipant,
        in availableFrame: CGRect
    ) -> some View {
        viewFactory.makeVideoParticipantView(
            participant: participant,
            id: participant.sessionId,
            availableFrame: availableFrame,
            contentMode: .scaleAspectFill,
            customData: ["videoOn": .bool(viewModel.callViewModel.callSettings.videoOn)],
            call: viewModel.callViewModel.call
        )
        .adjustVideoFrame(to: availableFrame.width, ratio: availableFrame.width / availableFrame.height)
        .modifier(viewFactory.makeLocalParticipantViewModifier(
            localParticipant: participant,
            callSettings: .init(get: { viewModel.callViewModel.callSettings }, set: { viewModel.callViewModel.callSettings = $0 }),
            call: viewModel.callViewModel.call
        ))
    }

    @ViewBuilder
    private func makeOverlayViewIfRequired(
        _ proxy: GeometryProxy
    ) -> some View {
        if (viewModel.screenSharingSession == nil || viewModel.isCurrentUserScreensharing),
           viewModel.participantsLayout == .grid,
           viewModel.participantsCount <= 3,
           !viewModel.hideUIElements,
           let participant = viewModel.localVideoPrimary ? viewModel.callViewModel.participants.first : viewModel.localParticipant {
            CornerDraggableView(
                content: { availableFrame in
                    viewFactory.makeVideoParticipantView(
                        participant: participant,
                        id: participant.sessionId,
                        availableFrame: availableFrame,
                        contentMode: .scaleAspectFill,
                        customData: [:],
                        call: viewModel.callViewModel.call
                    )
                    .modifier(
                        viewFactory.makeVideoCallParticipantModifier(
                            participant: participant,
                            call: viewModel.callViewModel.call,
                            availableFrame: availableFrame,
                            ratio: availableFrame.width / availableFrame.height,
                            showAllInfo: true
                        )
                    )
                },
                proxy: proxy,
                onTap: {
                    withAnimation {
                        if viewModel.participantsCount == 2 {
                            viewModel.callViewModel.localVideoPrimary.toggle()
                        }
                    }
                }
            )
            .accessibility(identifier: "cornerDraggableView")
            .padding()
        } else {
            EmptyView()
        }
    }
}
