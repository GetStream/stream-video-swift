//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct VideoParticipantsView: View {
    
    @StateObject var viewModel: CallViewModel
    var availableSize: CGSize
    var onViewRendering: (VideoRenderer, CallParticipant) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public var body: some View {
        ZStack {
            if participants.count <= 3 {
                VerticalParticipantsView(
                    participants: participants,
                    availableSize: availableSize
                ) { participant, view in
                    onViewRendering(view, participant)
                }
            } else if participants.count == 4 {
                TwoColumnParticipantsView(
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3]],
                    availableSize: availableSize
                ) { participant, view in
                    onViewRendering(view, participant)
                }
            } else if participants.count == 5 {
                TwoColumnParticipantsView(
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3], participants[4]],
                    availableSize: availableSize
                ) { participant, view in
                    onViewRendering(view, participant)
                }
            } else {
                ParticipantsGridView(
                    participants: participants,
                    availableSize: availableSize
                ) { participant, view in
                    onViewRendering(view, participant)
                } participantVisibilityChanged: { participant, isVisible in
                    onChangeTrackVisibility(participant, isVisible)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    var participants: [CallParticipant] {
        viewModel.participants
    }
}

struct TwoColumnParticipantsView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var leftColumnParticipants: [CallParticipant]
    var rightColumnParticipants: [CallParticipant]
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            VerticalParticipantsView(
                participants: leftColumnParticipants,
                availableSize: size,
                onViewUpdate: onViewUpdate
            )
            .adjustVideoFrame(to: size.width)
            
            VerticalParticipantsView(
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

struct VerticalParticipantsView: View {
            
    var participants: [CallParticipant]
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(participants) { participant in
                VideoCallParticipantView(
                    participant: participant,
                    availableSize: availableSize,
                    onViewUpdate: onViewUpdate
                )
                .adjustVideoFrame(to: availableSize.width, ratio: ratio)
                .overlay(
                    AudioIndicatorView(participant: participant)
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

struct VideoCallParticipantView: View {
    
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo
        
    let participant: CallParticipant
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    
    var body: some View {
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
        .border(Color.green, width: participant.isDominantSpeaker ? 2 : 0)
    }
    
    private var showVideo: Bool {
        participant.shouldDisplayTrack && streamVideo.videoConfig.videoEnabled
    }
}

struct AudioIndicatorView: View {
    
    @Injected(\.images) var images
    
    var participant: CallParticipant
    
    var body: some View {
        BottomRightView {
            (participant.hasAudio ? images.micTurnOn : images.micTurnOff)
                .foregroundColor(.white)
                .padding(.all, 4)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
        }
        .padding()
    }
}
