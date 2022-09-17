//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

public struct RoomView<Factory: ViewFactory>: View {
    
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
                VideoParticipantsView(
                    participants: viewModel.participants,
                    availableSize: reader.size,
                    onViewRendering: handleViewRendering(_:participant:),
                    onChangeTrackVisibility: viewModel.changeTrackVisbility(for:isVisible:)
                )

                VStack {
                    Spacer()
                    if let event = viewModel.participantEvent {
                        Text("\(event.user) \(event.action.display) the call.")
                            .padding(8)
                            .foregroundColor(colors.text)
                            .modifier(ShadowViewModifier())
                            .padding()
                    }
                    
                    viewFactory.makeCallControlsView(viewModel: viewModel)
                }
                
                TopRightView {
                    VStack(alignment: .trailing, spacing: padding) {
                        Button {
                            viewModel.participantsShown.toggle()
                        } label: {
                            images.participants
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.horizontal, 2)
                        
                        LocalVideoView(callSettings: viewModel.callSettings, showBackground: false) { view in
                            if let track = viewModel.localParticipant?.track {
                                view.add(track: track)
                            } else {
                                viewModel.renderLocalVideo(renderer: view)
                            }
                        }
                        .frame(width: reader.size.width / 4 + padding, height: reader.size.width / 3 + padding)
                        .background(Color.red)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .opacity(viewModel.localParticipant != nil ? 1 : 0)
                    }
                }
                
                if viewModel.participantsShown {
                    VStack {
                        CallParticipantsView(
                            viewModel: viewModel,
                            maxHeight: reader.size.height - padding
                        )
                        .padding()
                        .padding(.vertical, padding / 2)
                        
                        Spacer()
                    }
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
    
    private var participants: [CallParticipant] {
        viewModel.participants
    }
    
    private func handleViewRendering(_ view: StreamMTLVideoView, participant: CallParticipant) {
        if let track = participant.track, participant.id != streamVideo.userInfo.id {
            log.debug("adding track to a view \(view)")
            view.add(track: track)
            let prev = participant.trackSize
            if prev != view.bounds.size {
                participant.trackSize = view.bounds.size
                viewModel.callParticipants[participant.id] = participant
            }
        }
    }
}
