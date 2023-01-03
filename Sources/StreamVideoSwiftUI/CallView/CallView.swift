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
                    }
                }

                TopRightView {
                    VStack(alignment: .trailing, spacing: padding) {
                        if #available(iOS 14, *) {
                            HStack {
                                Button {
                                    withAnimation {
                                        viewModel.isMinimized = true
                                    }
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(colors.textInverted)
                                        .padding()
                                }

                                Spacer()
                                Button {
                                    viewModel.participantsShown.toggle()
                                } label: {
                                    images.participants
                                        .padding(.horizontal)
                                        .padding(.horizontal, 2)
                                        .foregroundColor(.white)
                                }
                            }
                        }

                        if viewModel.screensharingSession == nil {
                            CornerDragableView(
                                content: contentDragableView(size: reader.size),
                                proxy: reader
                            ) {
                                withAnimation {
                                    viewModel.localVideoPrimary.toggle()
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .opacity(viewModel.hideUIElements ? 0 : 1)

                if viewModel.participantsShown {
                    viewFactory.makeTrailingTopView(
                        viewModel: viewModel,
                        availableSize: reader.size
                    )
                    .opacity(viewModel.hideUIElements ? 0 : 1)
                }
            }
        }
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
                    availableSize: size
                ) { participant, view in
                    if let track = participant.track {
                        view.add(track: track)
                    }
                }
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
                viewModel.renderLocalVideo(renderer: view)
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
        if let track = participant.track, participant.id != viewModel.call?.sessionId {
            log.debug("adding track to a view \(view)")
            view.add(track: track)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                let prev = participant.trackSize
                if prev != view.bounds.size {
                    let updated = participant.withUpdated(trackSize: view.bounds.size)
                    viewModel.callParticipants[participant.id] = updated
                }
            }
        }
    }
}

@available(iOS 14.0, *)
public struct CallParticipantsInfoView: View {

    private let padding: CGFloat = 16

    @ObservedObject var viewModel: CallViewModel
    var availableSize: CGSize

    public var body: some View {
        VStack {
            CallParticipantsView(
                viewModel: viewModel,
                maxHeight: availableSize.height - padding
            )
            .padding()
            .padding(.vertical, padding / 2)

            Spacer()
        }
    }
}
