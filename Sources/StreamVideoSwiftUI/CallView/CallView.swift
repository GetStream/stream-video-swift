//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamWebRTC
import SwiftUI

public struct CallView<Factory: ViewFactory>: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors

    var viewFactory: Factory
    @ObservedObject var viewModel: CallViewModel

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            viewFactory
                .makeCallTopView(viewModel: viewModel)
                .presentParticipantEventsNotification(viewModel: viewModel)

            GeometryReader { videoFeedProxy in
                ZStack {
                    contentView(videoFeedProxy.frame(in: .global))

                    cornerDraggableView(videoFeedProxy)
                }
            }
            .padding([.leading, .trailing], 8)

            viewFactory.makeCallControlsView(viewModel: viewModel)
                .opacity(viewModel.hideUIElements ? 0 : 1)
        }
        .background(Color(colors.callBackground).edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .enablePictureInPicture(viewModel.isPictureInPictureEnabled)
        .presentParticipantListView(viewModel: viewModel, viewFactory: viewFactory)
    }

    @ViewBuilder
    private func contentView(_ availableFrame: CGRect) -> some View {
        if viewModel.localVideoPrimary, viewModel.participantsLayout == .grid {
            localVideoView(bounds: availableFrame)
                .accessibility(identifier: "localVideoView")
        } else if
            let screenSharingSession = viewModel.call?.state.screenSharingSession,
            viewModel.call?.state.isCurrentUserScreensharing == false {
            viewFactory.makeScreenSharingView(
                viewModel: viewModel,
                screensharingSession: screenSharingSession,
                availableFrame: availableFrame
            )
        } else {
            participantsView(bounds: availableFrame)
        }
    }

    private var shouldShowDraggableView: Bool {
        (viewModel.call?.state.screenSharingSession == nil || viewModel.call?.state.isCurrentUserScreensharing == true)
            && viewModel.participantsLayout == .grid
            && viewModel.participants.count <= 3
    }

    @ViewBuilder
    private func cornerDraggableView(_ proxy: GeometryProxy) -> some View {
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

    @ViewBuilder
    private func cornerDraggableViewContent(_ bounds: CGRect) -> some View {
        if viewModel.localVideoPrimary {
            minimizedView(bounds: bounds)
        } else {
            localVideoView(bounds: bounds)
        }
    }

    @ViewBuilder
    private func minimizedView(bounds: CGRect) -> some View {
        if let firstParticipant = viewModel.participants.first {
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

    @ViewBuilder
    private func localVideoView(bounds: CGRect) -> some View {
        if let localParticipant = viewModel.localParticipant {
            LocalVideoView(
                viewFactory: viewFactory,
                participant: localParticipant,
                callSettings: viewModel.callSettings,
                call: viewModel.call,
                availableFrame: bounds
            )
            .modifier(viewFactory.makeLocalParticipantViewModifier(
                localParticipant: localParticipant,
                callSettings: $viewModel.callSettings,
                call: viewModel.call
            ))
        } else {
            EmptyView()
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
