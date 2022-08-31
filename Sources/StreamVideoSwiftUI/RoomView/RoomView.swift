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
    
    var viewFactory: Factory
    @ObservedObject var viewModel: CallViewModel
    
    public init(viewFactory: Factory, viewModel: CallViewModel) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { reader in
            ZStack {
                if viewModel.participants.count <= 3 {
                    VerticalParticipantsView(
                        participants: viewModel.participants,
                        availableSize: reader.size
                    ) { participant, view in
                        handleViewRendering(view, participant: participant)
                    }
                } else if viewModel.participants.count == 4 {
                    TwoColumnParticipantsView(
                        leftColumnParticipants: [participants[0], participants[2]],
                        rightColumnParticipants: [participants[1], participants[3]],
                        availableSize: reader.size
                    ) { participant, view in
                        handleViewRendering(view, participant: participant)
                    }
                } else if viewModel.participants.count == 5 {
                    TwoColumnParticipantsView(
                        leftColumnParticipants: [participants[0], participants[2]],
                        rightColumnParticipants: [participants[1], participants[3], participants[4]],
                        availableSize: reader.size
                    ) { participant, view in
                        handleViewRendering(view, participant: participant)
                    }
                } else {
                    // TODO: define layout
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
                    
                    viewFactory.makeCallControlsView(viewModel: viewModel)
                }
                
                TopRightView {
                    VStack(alignment: .trailing, spacing: 16) {
                        Button {
                            viewModel.participantsShown.toggle()
                        } label: {
                            images.participants
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.horizontal, 2)
                        
                        LocalVideoView()
                            .frame(width: reader.size.width / 4, height: reader.size.width / 2)
                            .background(Color.red)
                            .cornerRadius(16)
                            .padding(.horizontal)
                    }
                }
                
                if viewModel.participantsShown {
                    VStack {
                        CallParticipantsView(
                            viewModel: viewModel,
                            maxHeight: reader.size.height - 16
                        )
                        .padding()
                        .padding(.vertical, 8)
                        
                        Spacer()
                    }
                }
            }
            .frame(width: reader.size.width)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var participants: [CallParticipant] {
        viewModel.participants
    }
    
    private func handleViewRendering(_ view: RTCMTLVideoView, participant: CallParticipant) {
        if let track = participant.track, participant.id != streamVideo.userInfo.id {
            log.debug("adding track to a view \(view)")
            track.add(view)
            let prev = participant.trackSize
            if prev != view.bounds.size {
                participant.trackSize = view.bounds.size
                viewModel.callParticipants[participant.id] = participant
            }
        }
    }
}

struct TwoColumnParticipantsView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var leftColumnParticipants: [CallParticipant]
    var rightColumnParticipants: [CallParticipant]
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, RTCMTLVideoView) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            VerticalParticipantsView(
                participants: leftColumnParticipants,
                availableSize: size,
                onViewUpdate: onViewUpdate
            )
            .adjustVideoFrame(to: size)
            
            VerticalParticipantsView(
                participants: rightColumnParticipants,
                availableSize: size,
                onViewUpdate: onViewUpdate
            )
            .adjustVideoFrame(to: size)
        }
        .frame(maxWidth: availableSize.width, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.vertical)
    }
    
    private var size: CGSize {
        CGSize(width: availableSize.width / 2, height: availableSize.height)
    }
}

struct VerticalParticipantsView: View {
    
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    
    var participants: [CallParticipant]
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, RTCMTLVideoView) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(participants) { participant in
                RTCMTLVideoViewSwiftUI(size: availableSize) { view in
                    onViewUpdate(participant, view)
                }
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    BottomRightView {
                        (participant.hasAudio ? images.micTurnOn : images.micTurnOff)
                            .foregroundColor(.white)
                            .padding(.all, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                    }
                    .padding()
                )
            }
        }
    }
}
