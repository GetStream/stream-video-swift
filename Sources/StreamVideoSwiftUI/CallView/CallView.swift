//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamWebRTC
import SwiftUI

public struct CallView<Factory: ViewFactory>: View {

    private enum ContentView: Equatable { case localVideo, screensharing, participantsView }

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
        PublisherSubscriptionView(
            initial: viewModel.isPictureInPictureEnabled,
            publisher: viewModel.$isPictureInPictureEnabled.eraseToAnyPublisher(),
            contentProvider: { isPictureInPictureEnabled in
                VStack {
                    topView

                    GeometryReader { videoFeedProxy in
                        ZStack {
                            contentView(videoFeedProxy.frame(in: .global))

                            cornerDraggableView(videoFeedProxy)
                        }
                    }
                    .padding([.leading, .trailing], 8)

                    bottomView
                }
                .background(Color(colors.callBackground).edgesIgnoringSafeArea(.all))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onDisappear {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
                .enablePictureInPicture(isPictureInPictureEnabled)
            }
        )
        .presentParticipantListView(viewModel: viewModel, viewFactory: viewFactory)
    }

    @ViewBuilder
    private var topView: some View {
        viewFactory
            .makeCallTopView(viewModel: viewModel)
            .presentParticipantEventsNotification(viewModel: viewModel)
    }

    @ViewBuilder
    private var bottomView: some View {
        PublisherSubscriptionView(
            initial: viewModel.hideUIElements,
            publisher: viewModel.$hideUIElements.eraseToAnyPublisher()
        ) { hideUIElements in
            viewFactory.makeCallControlsView(viewModel: viewModel)
                .opacity(hideUIElements ? 0 : 1)
        }
    }

    @ViewBuilder
    private func contentView(_ availableFrame: CGRect) -> some View {
        PublisherSubscriptionView(
            initial: contentViewValue,
            publisher: contentViewPublisher
        ) { _ in
            switch contentViewValue {
            case .localVideo:
                localVideoView(bounds: availableFrame)
                    .accessibility(identifier: "localVideoView")
            case .screensharing:
                if let screenSharingSession = viewModel.call?.state.screenSharingSession {
                    viewFactory.makeScreenSharingView(
                        viewModel: viewModel,
                        screensharingSession: screenSharingSession,
                        availableFrame: availableFrame
                    )
                } else {
                    participantsView(bounds: availableFrame)
                }
            case .participantsView:
                participantsView(bounds: availableFrame)
            }
        }
    }

    private var contentViewValue: ContentView {
        if viewModel.localVideoPrimary, viewModel.participantsLayout == .grid {
            return .localVideo
        } else if
            viewModel.call?.state.screenSharingSession != nil,
            viewModel.call?.state.isCurrentUserScreensharing == false
        {
            return .screensharing
        } else {
            return .participantsView
        }
    }

    private var contentViewPublisher: AnyPublisher<ContentView, Never> {
        guard let call = viewModel.call else {
            return Just(.localVideo).eraseToAnyPublisher()
        }
        return Publishers.CombineLatest4(
            viewModel.$localVideoPrimary.eraseToAnyPublisher(),
            viewModel.$participantsLayout.eraseToAnyPublisher(),
            call.state.$screenSharingSession.eraseToAnyPublisher(),
            call.state.$isCurrentUserScreensharing.eraseToAnyPublisher()
        )
        .map { localVideoPrimary, participantsLayout, screenSharingSession, isCurrentUserScreensharing in
            if localVideoPrimary, participantsLayout == .grid {
                return .localVideo
            } else if screenSharingSession != nil, !isCurrentUserScreensharing {
                return .screensharing
            } else {
                return .participantsView
            }
        }.eraseToAnyPublisher()
    }

    private var shouldShowDraggableView: Bool {
        (viewModel.call?.state.screenSharingSession == nil || viewModel.call?.state.isCurrentUserScreensharing == true)
            && viewModel.participantsLayout == .grid
            && viewModel.participants.count <= 3
    }

    private var shouldShowDraggablePublisher: AnyPublisher<Bool, Never> {
        guard let call = viewModel.call else {
            return Just(false).eraseToAnyPublisher()
        }
        let screenSharingPublisher = Publishers.combineLatest(
            call.state.$screenSharingSession.eraseToAnyPublisher(),
            call.state.$isCurrentUserScreensharing.eraseToAnyPublisher()
        )
        .map { (session: ScreenSharingSession?, isCurrentUserScreensharing: Bool) -> Bool in
            session == nil || isCurrentUserScreensharing == true
        }

        return Publishers.CombineLatest3(
            screenSharingPublisher,
            viewModel.$participantsLayout,
            viewModel.$callParticipants.map(\.count)
        )
        .map { (nooneIsScreenSharing, participantsLayout, participantsCount) in
            nooneIsScreenSharing
                && participantsLayout == .grid
                && participantsCount <= 3
        }
        .eraseToAnyPublisher()
    }

    @ViewBuilder
    private func cornerDraggableView(_ proxy: GeometryProxy) -> some View {
        PublisherSubscriptionView(
            initial: shouldShowDraggableView,
            publisher: shouldShowDraggablePublisher
        ) { shouldShowDraggableView in
            if shouldShowDraggableView {
                CornerDraggableView(
                    content: { cornerDraggableViewContent($0) },
                    proxy: proxy,
                    onTap: {
                        withAnimation {
                            if participants.count == 1 {
                                viewModel.localVideoPrimary.toggle()
                            }
                        }
                    }
                )
                .accessibility(identifier: "cornerDraggableView")
                .opacity(viewModel.hideUIElements ? 0 : 1)
                .padding()
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func cornerDraggableViewContent(_ bounds: CGRect) -> some View {
        PublisherSubscriptionView(
            initial: viewModel.localVideoPrimary,
            publisher: viewModel.$localVideoPrimary.eraseToAnyPublisher()
        ) { localVideoPrimary in
            if localVideoPrimary {
                minimizedView(bounds: bounds)
            } else {
                localVideoView(bounds: bounds)
            }
        }
    }

    @ViewBuilder
    private func minimizedView(bounds: CGRect) -> some View {
        PublisherSubscriptionView(
            initial: viewModel.participants,
            publisher: viewModel.$callParticipants.map { _ in viewModel.participants }.eraseToAnyPublisher()
        ) { participants in
            if let firstParticipant = participants.first {
                viewFactory.makeVideoParticipantView(
                    participant: firstParticipant,
                    id: firstParticipant.id,
                    availableFrame: bounds,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: viewModel.call
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: firstParticipant,
                        call: viewModel.call,
                        availableFrame: bounds,
                        ratio: bounds.width / bounds.height,
                        showAllInfo: true
                    )
                )
                .accessibility(identifier: "minimizedParticipantView")
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func localVideoView(bounds: CGRect) -> some View {
        PublisherSubscriptionView(
            initial: viewModel.call?.state.localParticipant,
            publisher: viewModel.call?.state.$localParticipant.eraseToAnyPublisher()
        ) { localParticipant in
            if let localParticipant {
                PublisherSubscriptionView(
                    initial: viewModel.callSettings,
                    publisher: viewModel.$callSettings.eraseToAnyPublisher()
                ) { callSettings in
                    LocalVideoView(
                        viewFactory: viewFactory,
                        participant: localParticipant,
                        callSettings: callSettings,
                        call: viewModel.call,
                        availableFrame: bounds
                    )
                    .modifier(viewFactory.makeLocalParticipantViewModifier(
                        localParticipant: localParticipant,
                        callSettings: .init(get: { viewModel.callSettings }, set: { viewModel.callSettings = $0 }),
                        call: viewModel.call
                    ))
                }
            } else {
                EmptyView()
            }
        }
    }

    private func participantsView(bounds: CGRect) -> some View {
        viewFactory.makeVideoParticipantsView(
            viewModel: viewModel,
            availableFrame: bounds,
            onChangeTrackVisibility: viewModel.changeTrackVisibility(for:isVisible:)
        )
    }

    private var participants: [CallParticipant] {
        viewModel.participants
    }
}
