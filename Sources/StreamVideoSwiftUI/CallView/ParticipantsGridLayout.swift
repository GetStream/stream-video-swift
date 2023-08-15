//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

public struct ParticipantsGridLayout<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableSize: CGSize
    var orientation: UIInterfaceOrientation
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory,
        call: Call?,
        participants: [CallParticipant],
        availableSize: CGSize,
        orientation: UIInterfaceOrientation,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participants = participants
        self.availableSize = availableSize
        self.onChangeTrackVisibility = onChangeTrackVisibility
        self.orientation = orientation
        self.call = call
    }
    
    public var body: some View {
        ZStack {
            if orientation.isPortrait || orientation == .unknown {
                VideoParticipantsViewPortrait(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableSize: availableSize,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                VideoParticipantsViewLandscape(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableSize: availableSize,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            }
        }
        .edgesIgnoringSafeArea(participants.count > 1 ? .bottom : .all)
    }
}

struct VideoParticipantsViewPortrait<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableSize: CGSize
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        ZStack {
            if participants.count <= 3 {
                VerticalParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableSize: availableSize,                    
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 4 {
                TwoColumnParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3]],
                    availableSize: availableSize,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 5 {
                TwoColumnParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3], participants[4]],
                    availableSize: availableSize,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableSize: availableSize,
                    isPortrait: true,
                    participantVisibilityChanged: { participant, isVisible in
                        onChangeTrackVisibility(participant, isVisible)
                    }
                )
            }
        }
    }
}

struct VideoParticipantsViewLandscape<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableSize: CGSize
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        ZStack {
            if participants.count <= 3 {
                HorizontalParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableSize: availableSize,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 4 {
                TwoRowParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    firstRowParticipants: [participants[0], participants[1]],
                    secondRowParticipants: [participants[2], participants[3]],
                    availableSize: availableSize,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 5 {
                TwoRowParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    firstRowParticipants: [participants[0], participants[1]],
                    secondRowParticipants: [participants[2], participants[3], participants[4]],
                    availableSize: availableSize,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableSize: availableSize,
                    isPortrait: false,
                    participantVisibilityChanged: { participant, isVisible in
                        onChangeTrackVisibility(participant, isVisible)
                    }
                )
            }
        }
    }
}

struct TwoColumnParticipantsView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var viewFactory: Factory
    var call: Call?
    var leftColumnParticipants: [CallParticipant]
    var rightColumnParticipants: [CallParticipant]
    var availableSize: CGSize
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            VerticalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: leftColumnParticipants,
                availableSize: size,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
            .adjustVideoFrame(to: size.width)
            
            VerticalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: rightColumnParticipants,
                availableSize: size,
                onChangeTrackVisibility: onChangeTrackVisibility
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

struct TwoRowParticipantsView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var viewFactory: Factory
    var call: Call?
    var firstRowParticipants: [CallParticipant]
    var secondRowParticipants: [CallParticipant]
    var availableSize: CGSize
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HorizontalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: firstRowParticipants,
                availableSize: size,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
            
            HorizontalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: secondRowParticipants,
                availableSize: size,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
        }
        .frame(maxWidth: availableSize.width, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
    
    private var size: CGSize {
        CGSize(width: availableSize.width, height: availableSize.height / 2)
    }
}

struct VerticalParticipantsView<Factory: ViewFactory>: View {
            
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableSize: CGSize
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(participants) { participant in
                viewFactory.makeVideoParticipantView(
                    participant: participant,
                    id: participant.id,
                    availableSize: availableSize,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: call
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: participant,
                        call: call,
                        availableSize: availableSize,
                        ratio: ratio,
                        showAllInfo: true
                    )
                )
                .onAppear {
                    onChangeTrackVisibility(participant, true)
                }
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


struct HorizontalParticipantsView<Factory: ViewFactory>: View {
            
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableSize: CGSize
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(participants) { participant in
                viewFactory.makeVideoParticipantView(
                    participant: participant,
                    id: participant.id,
                    availableSize: size,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: call
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: participant,
                        call: call,
                        availableSize: size,
                        ratio: ratio,
                        showAllInfo: true
                    )
                )
                .onAppear {
                    onChangeTrackVisibility(participant, true)
                }
            }
        }
    }
    
    private var size: CGSize {
        CGSize(width: availableWidth, height: availableSize.height)
    }
    
    private var ratio: CGFloat {
        availableWidth / availableSize.height
    }
    
    private var availableWidth: CGFloat {
        availableSize.width / CGFloat(participants.count)
    }
}
