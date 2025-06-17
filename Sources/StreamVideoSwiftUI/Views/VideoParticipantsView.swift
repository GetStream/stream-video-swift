//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamWebRTC
import SwiftUI

public struct VideoParticipantsView<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var viewModel: CallViewModel
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void

    @State var participants: [CallParticipant]
    var participantsPublisher: AnyPublisher<[CallParticipant], Never>

    @State var participantsLayout: ParticipantsLayout
    var participantsLayoutPublisher: AnyPublisher<ParticipantsLayout, Never>

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel,
        availableFrame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.availableFrame = availableFrame
        self.onChangeTrackVisibility = onChangeTrackVisibility

        participants = viewModel.participants
        participantsPublisher = viewModel
            .$participants
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .removeDuplicates(by: { lhs, rhs in
                let lhsSessionIds = lhs.map(\.sessionId)
                let rhsSessionIds = rhs.map(\.sessionId)
                return lhsSessionIds == rhsSessionIds
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        participantsLayout = viewModel.participantsLayout
        participantsLayoutPublisher = viewModel
            .$participantsLayout
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public var body: some View {
        contentView
            .onReceive(participantsPublisher) { participants = $0 }
            .onReceive(participantsLayoutPublisher) { participantsLayout = $0 }
            .debugViewRendering()
    }

    @ViewBuilder
    var contentView: some View {
        if participantsLayout == .fullScreen, let first = participants.first {
            ParticipantsFullScreenLayout(
                viewFactory: viewFactory,
                participant: first,
                call: viewModel.call,
                frame: availableFrame,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
        } else if participantsLayout == .spotlight, let first = participants.first {
            ParticipantsSpotlightLayout(
                viewFactory: viewFactory,
                participant: first,
                call: viewModel.call,
                participants: Array(participants.dropFirst()),
                frame: availableFrame,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
        } else {
            ParticipantsGridLayout(
                viewFactory: viewFactory,
                call: viewModel.call,
                participants: participants,
                availableFrame: availableFrame,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
        }
    }
}
