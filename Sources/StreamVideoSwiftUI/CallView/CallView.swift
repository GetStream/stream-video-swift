//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

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
                        } else if let screensharing = viewModel.screensharingSession {
                            viewFactory.makeScreenSharingView(
                                viewModel: viewModel,
                                screensharingSession: screensharing,
                                availableSize: videoFeedProxy.size
                            )
                        } else {
                            participantsView(size: videoFeedProxy.size)
                        }
                    }

                    viewFactory.makeCallControlsView(viewModel: viewModel)
                        .opacity(viewModel.hideUIElements ? 0 : 1)
                }
                
                VStack {
                    Spacer()
                    if let event = viewModel.participantEvent {
                        Text("\(event.user) \(event.action.display) the call.")
                            .padding(8)
                            .foregroundColor(colors.text)
                            .modifier(ShadowViewModifier())
                            .padding()
                            .accessibility(identifier: "participantEventLabel")
                    }
                }
                                
                TopRightView {
                    VStack(alignment: .trailing, spacing: padding) {
                        viewFactory.makeCallTopView(viewModel: viewModel)
                        
                        if viewModel.screensharingSession == nil, viewModel.participantsLayout == .grid {
                            CornerDragableView(
                                content: contentDragableView(size: reader.size),
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
                    }
                    .padding(.top, 4)
                }
                .opacity(viewModel.hideUIElements ? 0 : 1)
                
                if viewModel.participantsShown {
                    viewFactory.makeParticipantsListView(
                        viewModel: viewModel,
                        availableSize: reader.size
                    )
                    .opacity(viewModel.hideUIElements ? 0 : 1)
                    .accessibility(identifier: "trailingTopView")
                }
            }
        }
        .background(Color(colors.callBackground))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    @ViewBuilder
    private func contentDragableView(size: CGSize) -> some View {
        if !viewModel.localVideoPrimary {
            localVideoView
                .cornerRadius(16)
                .padding(.horizontal)
        } else {
            minimizedView(size: size)
        }
    }
    
    private func minimizedView(size: CGSize) -> some View {
        Group {
            if !viewModel.participants.isEmpty {
                VideoCallParticipantView(
                    participant: viewModel.participants[0],
                    availableSize: size,
                    contentMode: .scaleAspectFill
                ) { participant, view in
                    view.handleViewRendering(for: participant) { size, participant in
                        viewModel.updateTrackSize(size, for: participant)
                    }
                }
                .accessibility(identifier: "minimizedParticipantView")
            } else {
                EmptyView()
            }
        }
    }
    
    private var localVideoView: some View {
        LocalVideoView(callSettings: viewModel.callSettings, showBackground: false) { view in
            if let track = viewModel.localParticipant?.track {
                view.add(track: track)
            } else {
                viewModel.startCapturingLocalVideo()
            }
        }
        .opacity(viewModel.localParticipant != nil ? 1 : 0)
    }
    
    private func participantsView(size: CGSize) -> some View {
        viewFactory.makeVideoParticipantsView(
            viewModel: viewModel,
            availableSize: size,
            onViewRendering: handleViewRendering(_:participant:),
            onChangeTrackVisibility: viewModel.changeTrackVisbility(for:isVisible:)
        )
    }
    
    private var participants: [CallParticipant] {
        viewModel.participants
    }
    
    private func handleViewRendering(_ view: VideoRenderer, participant: CallParticipant) {
        view.handleViewRendering(for: participant) { size, participant in
            viewModel.updateTrackSize(size, for: participant)
        }
    }
}
