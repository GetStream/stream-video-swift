//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct MinimizedCallView<Factory: ViewFactory>: View {
    var viewFactory: Factory
    var viewModel: CallViewModel

    @State var participant: CallParticipant?
    var participantPublisher: AnyPublisher<CallParticipant?, Never>

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel

        participant = viewModel.participants.first
        participantPublisher = viewModel
            .$callParticipants
            .map(\.values.first)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            CornerDraggableView(
                content: { content(for: $0) },
                proxy: proxy,
                onTap: { viewModel.isMinimized = false }
            )
        }
        .onReceive(participantPublisher) { participant = $0 }
        .debugViewRendering()
    }
    
    func content(for availableFrame: CGRect) -> some View {
        Group {
            if let participant {
                VideoCallParticipantView(
                    viewFactory: viewFactory,
                    participant: participant,
                    availableFrame: availableFrame,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: viewModel.call
                )
            } else {
                EmptyView()
            }
        }
    }
}
