//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

public struct RemoteParticipantsView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    
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
                    // TODO: Layout is broken here.
                    Grid4ParticipantsView(
                        participants: viewModel.participants,
                        availableSize: reader.size
                    ) { participant, view in
                        handleViewRendering(view, participant: participant)
                    }
                } else if viewModel.participants.count == 5 {
                    Grid5ParticipantsView(
                        participants: viewModel.participants,
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
                            .foregroundColor(.white)
                            .modifier(ShadowViewModifier())
                            .padding()
                    }
                    
                    viewFactory.makeCallControlsView(viewModel: viewModel)
                }
                
                TopRightView {
                    LocalVideoView()
                        .frame(width: reader.size.width / 4, height: reader.size.width / 2)
                        .background(Color.red)
                        .cornerRadius(16)
                        .padding()
                }
            }
            .frame(width: reader.size.width)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct Grid4ParticipantsView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var participants: [CallParticipant]
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, RTCMTLVideoView) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            VerticalParticipantsView(
                participants: [participants[0], participants[2]],
                availableSize: size,
                onViewUpdate: onViewUpdate
            )
            .frame(width: size.width)
            
            VerticalParticipantsView(
                participants: [participants[1], participants[3]],
                availableSize: size,
                onViewUpdate: onViewUpdate
            )
            .frame(width: size.width)
        }
    }
    
    private var size: CGSize {
        CGSize(width: availableSize.width / 2, height: availableSize.height)
    }
}

struct Grid5ParticipantsView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var participants: [CallParticipant]
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, RTCMTLVideoView) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            VerticalParticipantsView(
                participants: [participants[0], participants[2]],
                availableSize: size,
                onViewUpdate: onViewUpdate
            )
            
            VerticalParticipantsView(
                participants: [participants[1], participants[3], participants[4]],
                availableSize: size,
                onViewUpdate: onViewUpdate
            )
        }
    }
    
    private var size: CGSize {
        CGSize(width: availableSize.width / 2, height: availableSize.height)
    }
}

struct VerticalParticipantsView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
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
            }
        }
    }
}
