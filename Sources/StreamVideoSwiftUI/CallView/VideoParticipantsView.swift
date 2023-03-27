//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct VideoParticipantsView<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    @ObservedObject var viewModel: CallViewModel
    var availableSize: CGSize
    var onViewRendering: (VideoRenderer, CallParticipant) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    @State private var orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
    
    public init(
        viewFactory: Factory,
        viewModel: CallViewModel,
        availableSize: CGSize,
        onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.availableSize = availableSize
        self.onViewRendering = onViewRendering
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }
    
    public var body: some View {
        ZStack {
            if viewModel.participantsLayout == .fullScreen, let fullScreenParticipant {
                ParticipantsFullScreenLayout(
                    viewFactory: viewFactory,
                    participant: fullScreenParticipant,
                    size: availableSize,
                    pinnedParticipant: $viewModel.pinnedParticipant,
                    onViewRendering: onViewRendering,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if viewModel.participantsLayout == .spotlight, let fullScreenParticipant {
                ParticipantsSpotlightLayout(
                    viewFactory: viewFactory,
                    participant: fullScreenParticipant,
                    participants: viewModel.participants,
                    size: availableSize,
                    pinnedParticipant: $viewModel.pinnedParticipant,
                    onViewRendering: onViewRendering,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridLayout(
                    viewFactory: viewFactory,
                    participants: viewModel.participants,
                    pinnedParticipant: $viewModel.pinnedParticipant,
                    availableSize: availableSize,
                    orientation: orientation,
                    onViewRendering: onViewRendering,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            }
        }
        .onRotate { newOrientation in
            orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
        }
    }
    
    //TODO: move this away from here
    var fullScreenParticipant: CallParticipant? {
        viewModel.pinnedParticipant ?? viewModel.callParticipants.first(where: { (_, value) in
            value.isDominantSpeaker
        }).map(\.value) ?? viewModel.participants.first
    }
}

public struct VideoCallParticipantModifier: ViewModifier {
            
    var participant: CallParticipant
    @Binding var pinnedParticipant: CallParticipant?
    var participantCount: Int
    var availableSize: CGSize
    var ratio: CGFloat
    
    public init(
        participant: CallParticipant,
        pinnedParticipant: Binding<CallParticipant?>,
        participantCount: Int,
        availableSize: CGSize,
        ratio: CGFloat
    ) {
        self.participant = participant
        _pinnedParticipant = pinnedParticipant
        self.participantCount = participantCount
        self.availableSize = availableSize
        self.ratio = ratio
    }
    
    public func body(content: Content) -> some View {
        content
            .adjustVideoFrame(to: availableSize.width, ratio: ratio)
            .overlay(
                ZStack {
                    BottomView(content: {
                        HStack {
                            AudioIndicatorView(participant: participant)
                            Spacer()
                            ConnectionQualityIndicator(
                                connectionQuality: participant.connectionQuality
                            )
                        }
                        .padding(.bottom, 2)
                    })
                        .padding()
                    
                    if participant.isSpeaking && participantCount > 1 {
                        Rectangle()
                            .strokeBorder(Color.blue.opacity(0.7), lineWidth: 2)
                    }
                }
            )
            .onTapGesture(count: 2, perform: {
                if participant.id == pinnedParticipant?.id {
                    self.pinnedParticipant = nil
                } else {
                    self.pinnedParticipant = participant
                }
            })
    }
}

public struct VideoCallParticipantView: View {
    
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo
        
    let participant: CallParticipant
    var availableSize: CGSize
    var contentMode: UIView.ContentMode
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    
    public init(
        participant: CallParticipant,
        availableSize: CGSize,
        contentMode: UIView.ContentMode,
        onViewUpdate: @escaping (CallParticipant, VideoRenderer) -> Void
    ) {
        self.participant = participant
        self.availableSize = availableSize
        self.contentMode = contentMode
        self.onViewUpdate = onViewUpdate
    }
    
    public var body: some View {
        VideoRendererView(
            id: participant.id,
            size: availableSize,
            contentMode: contentMode
        ) { view in
            onViewUpdate(participant, view)
        }
        .opacity(showVideo ? 1 : 0)
        .edgesIgnoringSafeArea(.all)
        .overlay(
            CallParticipantImageView(
                id: participant.id,
                name: participant.name,
                imageURL: participant.profileImageURL
            )
            .frame(maxWidth: availableSize.width)
            .opacity(showVideo ? 0 : 1)
        )
        .accessibility(identifier: showVideo ? "CallParticipantVideoView" : "CallParticipantImageView")
    }
    
    private var showVideo: Bool {
        participant.shouldDisplayTrack && streamVideo.videoConfig.videoEnabled
    }
}

struct AudioIndicatorView: View {
    
    @Injected(\.images) var images
    @Injected(\.fonts) var fonts
    
    var participant: CallParticipant
    
    var body: some View {
        HStack(spacing: 2) {
            Text(participant.name)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(fonts.caption1)
                .accessibility(identifier: "participantName")
                        
            (participant.hasAudio ? images.micTurnOn : images.micTurnOff)
                .foregroundColor(.white)
                .padding(.all, 4)
                .accessibility(identifier: participant.hasAudio ? "participantMicIsOn" : "participantMicIsOff")
        }
        .padding(.all, 2)
        .padding(.horizontal, 4)
        .frame(height: 28)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
    }
}
