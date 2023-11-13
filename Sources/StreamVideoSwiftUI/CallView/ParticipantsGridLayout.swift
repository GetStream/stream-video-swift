//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import StreamWebRTC

public struct ParticipantsGridLayout<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableFrame: CGRect
    var orientation: UIInterfaceOrientation
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory,
        call: Call?,
        participants: [CallParticipant],
        availableFrame: CGRect,
        orientation: UIInterfaceOrientation,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participants = participants
        self.availableFrame = availableFrame
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
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                VideoParticipantsViewLandscape(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
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
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        ZStack {
            if participants.count <= 3 {
                VerticalParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 4 {
                TwoColumnParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3]],
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 5 {
                TwoColumnParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3], participants[4]],
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
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
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        ZStack {
            if participants.count <= 3 {
                HorizontalParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 4 {
                TwoRowParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    firstRowParticipants: [participants[0], participants[1]],
                    secondRowParticipants: [participants[2], participants[3]],
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 5 {
                TwoRowParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    firstRowParticipants: [participants[0], participants[1]],
                    secondRowParticipants: [participants[2], participants[3], participants[4]],
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
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
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            VerticalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: leftColumnParticipants,
                availableFrame: bounds,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
            .adjustVideoFrame(to: bounds.size.width)

            VerticalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: rightColumnParticipants,
                availableFrame: bounds,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
            .adjustVideoFrame(to: bounds.size.width)
        }
        .frame(maxWidth: availableFrame.size.width, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
    
    private var bounds: CGRect {
        CGRect(
            origin: .zero,
            size: CGSize(width: availableFrame.size.width / 2, height: availableFrame.size.height)
        )
    }
}

struct TwoRowParticipantsView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var viewFactory: Factory
    var call: Call?
    var firstRowParticipants: [CallParticipant]
    var secondRowParticipants: [CallParticipant]
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HorizontalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: firstRowParticipants,
                availableFrame: bounds,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
            
            HorizontalParticipantsView(
                viewFactory: viewFactory,
                call: call,
                participants: secondRowParticipants,
                availableFrame: bounds,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
        }
        .frame(maxWidth: availableFrame.width, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
    
    private var bounds: CGRect {
        .init(
            origin: .zero,
            size: CGSize(width: availableFrame.width, height: availableFrame.height / 2)
        )
    }
}

struct VerticalParticipantsView<Factory: ViewFactory>: View {
            
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(participants) { participant in
                viewFactory.makeVideoParticipantView(
                    participant: participant,
                    id: participant.id,
                    availableFrame: availableFrame,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: call
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: participant,
                        call: call,
                        availableFrame: availableFrame,
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
        availableFrame.width / availableHeight
    }
    
    private var availableHeight: CGFloat {
        availableFrame.height / CGFloat(participants.count)
    }
}


struct HorizontalParticipantsView<Factory: ViewFactory>: View {
            
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(participants) { participant in
                viewFactory.makeVideoParticipantView(
                    participant: participant,
                    id: participant.id,
                    availableFrame: bounds,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: call
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: participant,
                        call: call,
                        availableFrame: bounds,
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
    
    private var bounds: CGRect {
        .init(
            origin: .zero,
            size: CGSize(width: availableWidth, height: availableFrame.height)
        )
    }
    
    private var ratio: CGFloat {
        availableWidth / availableFrame.height
    }
    
    private var availableWidth: CGFloat {
        availableFrame.width / CGFloat(participants.count)
    }
}
