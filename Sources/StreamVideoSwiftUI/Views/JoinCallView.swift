//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

struct JoinCallView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors

    var viewFactory: Factory
    var viewModel: LobbyViewModel

    @State var participants: [User]
    var participantsPublisher: AnyPublisher<[User], Never>

    init(
        viewFactory: Factory,
        viewModel: LobbyViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel

        participants = viewModel.participants
        participantsPublisher = viewModel.$participants.eraseToAnyPublisher()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(waitingRoomDescription)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(identifier: "callParticipantsCount")
                .streamAccessibility(value: "\(participants.count)")

            if #available(iOS 14, *) {
                if !participants.isEmpty {
                    ParticipantsInCallView(
                        viewFactory: viewFactory,
                        callParticipants: participants
                    )
                }
            }
            
            Button {
                viewModel.didTapJoin()
            } label: {
                Text(L10n.WaitingRoom.join)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .accessibility(identifier: "joinCall")
            }
            .frame(height: 50)
            .background(colors.primaryButtonBackground)
            .cornerRadius(16)
            .foregroundColor(.white)
        }
        .padding()
        .background(colors.lobbySecondaryBackground)
        .cornerRadius(16)
        .onReceive(participantsPublisher) { participants = $0 }
        .debugViewRendering()
    }
    
    private var waitingRoomDescription: String {
        "\(L10n.WaitingRoom.description) \(L10n.WaitingRoom.numberOfParticipants(participants.count))"
    }
    
    private var otherParticipantsCount: Int {
        let count = participants.count - 1
        if count > 0 {
            return count
        } else {
            return 0
        }
    }
}
