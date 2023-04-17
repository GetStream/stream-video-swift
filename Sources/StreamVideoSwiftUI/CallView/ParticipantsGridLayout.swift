//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

public struct ParticipantsGridLayout<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var participants: [CallParticipant]
    @Binding var pinnedParticipant: CallParticipant?
    var availableSize: CGSize
    var orientation: UIInterfaceOrientation
    var onViewRendering: (VideoRenderer, CallParticipant) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory,
        participants: [CallParticipant],
        pinnedParticipant: Binding<CallParticipant?>,
        availableSize: CGSize,
        orientation: UIInterfaceOrientation,
        onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participants = participants
        self.availableSize = availableSize
        self.onViewRendering = onViewRendering
        self.onChangeTrackVisibility = onChangeTrackVisibility
        self.orientation = orientation
        _pinnedParticipant = pinnedParticipant
    }
    
    public var body: some View {
        ZStack {
            if orientation.isPortrait || orientation == .unknown {
                VideoParticipantsViewPortrait(
                    viewFactory: viewFactory,
                    participants: participants,
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    onViewRendering: onViewRendering,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                VideoParticipantsViewLandscape(
                    viewFactory: viewFactory,
                    participants: participants,
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    onViewRendering: onViewRendering,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            }
        }
        .edgesIgnoringSafeArea(participants.count > 1 ? .bottom : .all)
    }
}

struct VideoParticipantsViewPortrait<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var participants: [CallParticipant]
    @Binding var pinnedParticipant: CallParticipant?
    var availableSize: CGSize
    var onViewRendering: (VideoRenderer, CallParticipant) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        ZStack {
            if participants.count <= 3 {
                VerticalParticipantsView(
                    viewFactory: viewFactory,
                    participants: participants,
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    onViewUpdate: { participant, view in
                        onViewRendering(view, participant)
                    },
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 4 {
                TwoColumnParticipantsView(
                    viewFactory: viewFactory,
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3]],
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    onViewUpdate: { participant, view in
                        onViewRendering(view, participant)
                    },
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 5 {
                TwoColumnParticipantsView(
                    viewFactory: viewFactory,
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3], participants[4]],
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    onViewUpdate: { participant, view in
                        onViewRendering(view, participant)
                    },
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridView(
                    viewFactory: viewFactory,
                    participants: participants,
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    isPortrait: true
                ) { participant, view in
                    onViewRendering(view, participant)
                } participantVisibilityChanged: { participant, isVisible in
                    onChangeTrackVisibility(participant, isVisible)
                }
            }
        }
    }
}

struct VideoParticipantsViewLandscape<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var participants: [CallParticipant]
    @Binding var pinnedParticipant: CallParticipant?
    var availableSize: CGSize
    var onViewRendering: (VideoRenderer, CallParticipant) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        ZStack {
            if participants.count <= 3 {
                HorizontalParticipantsView(
                    viewFactory: viewFactory,
                    participants: participants,
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    onViewUpdate: { participant, view in
                        onViewRendering(view, participant)
                    },
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 4 {
                TwoRowParticipantsView(
                    viewFactory: viewFactory,
                    firstRowParticipants: [participants[0], participants[1]],
                    secondRowParticipants: [participants[2], participants[3]],
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    onViewUpdate: { participant, view in
                        onViewRendering(view, participant)
                    },
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 5 {
                TwoRowParticipantsView(
                    viewFactory: viewFactory,
                    firstRowParticipants: [participants[0], participants[1]],
                    secondRowParticipants: [participants[2], participants[3], participants[4]],
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    onViewUpdate: { participant, view in
                        onViewRendering(view, participant)
                    },
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridView(
                    viewFactory: viewFactory,
                    participants: participants,
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    isPortrait: false
                ) { participant, view in
                    onViewRendering(view, participant)
                } participantVisibilityChanged: { participant, isVisible in
                    onChangeTrackVisibility(participant, isVisible)
                }
            }
        }
    }
}

struct TwoColumnParticipantsView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var viewFactory: Factory
    var leftColumnParticipants: [CallParticipant]
    var rightColumnParticipants: [CallParticipant]
    @Binding var pinnedParticipant: CallParticipant?
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            VerticalParticipantsView(
                viewFactory: viewFactory,
                participants: leftColumnParticipants,
                pinnedParticipant: $pinnedParticipant,
                availableSize: size,
                onViewUpdate: onViewUpdate,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
            .adjustVideoFrame(to: size.width)
            
            VerticalParticipantsView(
                viewFactory: viewFactory,
                participants: rightColumnParticipants,
                pinnedParticipant: $pinnedParticipant,
                availableSize: size,
                onViewUpdate: onViewUpdate,
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
    var firstRowParticipants: [CallParticipant]
    var secondRowParticipants: [CallParticipant]
    @Binding var pinnedParticipant: CallParticipant?
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HorizontalParticipantsView(
                viewFactory: viewFactory,
                participants: firstRowParticipants,
                pinnedParticipant: $pinnedParticipant,
                availableSize: size,
                onViewUpdate: onViewUpdate,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
            
            HorizontalParticipantsView(
                viewFactory: viewFactory,
                participants: secondRowParticipants,
                pinnedParticipant: $pinnedParticipant,
                availableSize: size,
                onViewUpdate: onViewUpdate,
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
    var participants: [CallParticipant]
    @Binding var pinnedParticipant: CallParticipant?
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(participants) { participant in
                viewFactory.makeVideoParticipantView(
                    participant: participant,
                    availableSize: availableSize,
                    contentMode: .scaleAspectFill,
                    onViewUpdate: onViewUpdate
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: participant,
                        participantCount: participants.count,
                        pinnedParticipant: $pinnedParticipant,
                        availableSize: availableSize,
                        ratio: ratio
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
    var participants: [CallParticipant]
    @Binding var pinnedParticipant: CallParticipant?
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(participants) { participant in
                viewFactory.makeVideoParticipantView(
                    participant: participant,
                    availableSize: size,
                    contentMode: .scaleAspectFill,
                    onViewUpdate: onViewUpdate
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: participant,
                        participantCount: participants.count,
                        pinnedParticipant: $pinnedParticipant,
                        availableSize: size,
                        ratio: ratio
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
