//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import StreamWebRTC

public struct CallView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    private let padding: CGFloat = 16
    
    var viewFactory: Factory
    @ObservedObject var viewModel: CallViewModel
    
    public init(viewFactory: Factory, viewModel: CallViewModel) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { reader in
            ZStack {
                VStack(spacing: 0) {
                    GeometryReader { videoFeedProxy in
                        if viewModel.localVideoPrimary {
                            localVideoView
                                .edgesIgnoringSafeArea(.top)
                                .accessibility(identifier: "localVideoView")
                        } else if let screenSharingSession = viewModel.call?.state.screenSharingSession,
                                    viewModel.call?.state.isCurrentUserScreensharing == false {
                            viewFactory.makeScreenSharingView(
                                viewModel: viewModel,
                                screensharingSession: screenSharingSession,
                                availableFrame: videoFeedProxy.frame(in: .global)
                            )
                        } else {
                            participantsView(bounds: videoFeedProxy.frame(in: .global))
                        }
                    }

                    viewFactory.makeCallControlsView(viewModel: viewModel)
                        .opacity(viewModel.hideUIElements ? 0 : 1)
                }

                VStack(alignment: .trailing, spacing: padding) {
                    viewFactory.makeCallTopView(viewModel: viewModel)

                    if (viewModel.call?.state.screenSharingSession == nil || viewModel.call?.state.isCurrentUserScreensharing == true),
                       viewModel.participantsLayout == .grid, viewModel.participants.count <= 3 {
                        CornerDragableView(
                            content: contentDragableView(bounds: reader.frame(in: .global)),
                            proxy: reader
                        ) {
                            withAnimation {
                                if participants.count == 1 {
                                    viewModel.localVideoPrimary.toggle()
                                }
                            }
                        }
                        .accessibility(identifier: "cornerDragableView")
                    }

                    Spacer()
                }
                .padding(.top, 4)
                .opacity(viewModel.hideUIElements ? 0 : 1)

                VStack {
                    if let event = viewModel.participantEvent {
                        Text("\(event.user) \(event.action.display) the call.")
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .foregroundColor(colors.text)
                            .modifier(ShadowViewModifier())
                            .padding()
                            .accessibility(identifier: "participantEventLabel")
                        #if STREAM_E2E_TESTS
                            .offset(y: 300)
                        #endif
                    }

                    Spacer()
                }

                if viewModel.participantsShown {
                    viewFactory.makeParticipantsListView(
                        viewModel: viewModel,
                        availableFrame: reader.frame(in: .global)
                    )
                    .opacity(viewModel.hideUIElements ? 0 : 1)
                    .accessibility(identifier: "trailingTopView")
                }
            }
        }
        .background(Color(colors.callBackground).edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    @ViewBuilder
    private func contentDragableView(bounds: CGRect) -> some View {
        if !viewModel.localVideoPrimary {
            localVideoView
                .cornerRadius(16)
                .padding(.horizontal)
        } else {
            minimizedView(bounds: bounds)
        }
    }
    
    private func minimizedView(bounds: CGRect) -> some View {
        Group {
            if !viewModel.participants.isEmpty {
                VideoCallParticipantView(
                    participant: viewModel.participants[0],
                    availableFrame: bounds,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: viewModel.call
                )
                .accessibility(identifier: "minimizedParticipantView")
            } else {
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private var localVideoView: some View {
        if let localParticipant = viewModel.localParticipant {
            LocalVideoView(
                viewFactory: viewFactory,
                participant: localParticipant,
                callSettings: viewModel.callSettings,
                call: viewModel.call
            )
            .opacity(viewModel.localParticipant != nil ? 1 : 0)
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
