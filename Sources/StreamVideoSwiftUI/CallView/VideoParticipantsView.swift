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
    
    public init(
        viewFactory: Factory,
        viewModel: CallViewModel,
        availableSize: CGSize,
        onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.availableSize = availableSize
        self.onViewRendering = onViewRendering
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }
    
    public var body: some View {
        ZStack {
            if participants.count <= 3 {
                VerticalParticipantsView(
                    viewFactory: viewFactory,
                    participants: participants,
                    availableSize: availableSize
                ) { participant, view in
                    onViewRendering(view, participant)
                }
            } else if participants.count == 4 {
                TwoColumnParticipantsView(
                    viewFactory: viewFactory,
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3]],
                    availableSize: availableSize
                ) { participant, view in
                    onViewRendering(view, participant)
                }
            } else if participants.count == 5 {
                TwoColumnParticipantsView(
                    viewFactory: viewFactory,
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3], participants[4]],
                    availableSize: availableSize
                ) { participant, view in
                    onViewRendering(view, participant)
                }
            } else {
                ParticipantsGridView(
                    viewFactory: viewFactory,
                    participants: participants,
                    availableSize: availableSize
                ) { participant, view in
                    onViewRendering(view, participant)
                } participantVisibilityChanged: { participant, isVisible in
                    onChangeTrackVisibility(participant, isVisible)
                }
            }
        }
        .edgesIgnoringSafeArea(participants.count > 1 ? .bottom : .all)
    }
    
    var participants: [CallParticipant] {
        viewModel.participants
    }
}

struct TwoColumnParticipantsView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var viewFactory: Factory
    var leftColumnParticipants: [CallParticipant]
    var rightColumnParticipants: [CallParticipant]
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            VerticalParticipantsView(
                viewFactory: viewFactory,
                participants: leftColumnParticipants,
                availableSize: size,
                onViewUpdate: onViewUpdate
            )
            .adjustVideoFrame(to: size.width)
            
            VerticalParticipantsView(
                viewFactory: viewFactory,
                participants: rightColumnParticipants,
                availableSize: size,
                onViewUpdate: onViewUpdate
            )
            .adjustVideoFrame(to: size.width)
        }
        .frame(maxWidth: availableSize.width, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
    
    private var size: CGSize {
        CGSize(width: availableSize.width / 2, height: availableSize.height)
    }
}

struct VerticalParticipantsView<Factory: ViewFactory>: View {
            
    var viewFactory: Factory
    var participants: [CallParticipant]
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(participants) { participant in
                viewFactory.makeVideoParticipantView(
                    participant: participant,
                    availableSize: availableSize,
                    onViewUpdate: onViewUpdate
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: participant,
                        participantCount: participants.count,
                        availableSize: availableSize,
                        ratio: ratio
                    )
                )
            }
        }
    }
    
    private var ratio: CGFloat {
        availableSize.width / availableHeight
    }
    
    private var availableHeight: CGFloat {
        availableSize.height / CGFloat(participants.count)
    }
}

public struct VideoCallParticipantModifier: ViewModifier {
            
    var participant: CallParticipant
    var participantCount: Int
    var availableSize: CGSize
    var ratio: CGFloat
    
    public init(
        participant: CallParticipant,
        participantCount: Int,
        availableSize: CGSize,
        ratio: CGFloat
    ) {
        self.participant = participant
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
    }
}

public struct VideoCallParticipantView: View {
    
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo
        
    let participant: CallParticipant
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    
    public init(
        participant: CallParticipant,
        availableSize: CGSize,
        onViewUpdate: @escaping (CallParticipant, VideoRenderer) -> Void
    ) {
        self.participant = participant
        self.availableSize = availableSize
        self.onViewUpdate = onViewUpdate
    }
    
    public var body: some View {
        VideoRendererView(id: participant.id, size: availableSize) { view in
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
                        
            (participant.hasAudio ? images.micTurnOn : images.micTurnOff)
                .foregroundColor(.white)
                .padding(.all, 4)
        }
        .padding(.all, 2)
        .padding(.horizontal, 4)
        .frame(height: 28)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
    }
}
