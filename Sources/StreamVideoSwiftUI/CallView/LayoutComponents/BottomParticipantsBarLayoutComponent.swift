//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct BottomParticipantsBarLayoutComponent<Factory: ViewFactory>: View {

    public var viewFactory: Factory
    public var participants: [CallParticipant]
    public var frame: CGRect
    public var call: Call?
    public var thumbnailSize: CGFloat
    public var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void

    private let barFrame: CGRect
    private let itemFrame: CGRect

    public init(
        viewFactory: Factory,
        participants: [CallParticipant],
        frame: CGRect,
        call: Call?,
        thumbnailSize: CGFloat = 120,
        onChangeTrackVisibility: @escaping (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participants = participants
        self.frame = frame
        self.call = call
        self.thumbnailSize = thumbnailSize
        self.onChangeTrackVisibility = onChangeTrackVisibility
        self.barFrame = .init(
            origin: .init(x: frame.origin.x, y: frame.maxY - thumbnailSize),
            size: CGSize(width: frame.size.width, height: thumbnailSize)
        )
        self.itemFrame = .init(
            origin: .zero,
            size: .init(
                width: barFrame.height,
                height: barFrame.height
            )
        )
    }

    public var body: some View {
        ScrollView(.horizontal) {
            HorizontalContainer {
                ForEach(participants) { participant in
                    viewFactory.makeVideoParticipantView(
                        participant: participant,
                        id: participant.id,
                        availableFrame: itemFrame,
                        contentMode: .scaleAspectFill,
                        customData: [:],
                        call: call
                    )
                    .modifier(
                        viewFactory.makeVideoCallParticipantModifier(
                            participant: participant,
                            call: call,
                            availableFrame: itemFrame,
                            ratio: itemFrame.width / itemFrame.height,
                            showAllInfo: false
                        )
                    )
                    .visibilityObservation(in: barFrame) { onChangeTrackVisibility(participant, $0) }
                    .cornerRadius(8)
                    .accessibility(identifier: "bottomParticipantsBarParticipipant")
                }
            }
            .frame(height: barFrame.height)
            .cornerRadius(8)
        }
        .padding()
//        .padding(.bottom)
        .accessibility(identifier: "bottomParticipantsBar")
    }
}
