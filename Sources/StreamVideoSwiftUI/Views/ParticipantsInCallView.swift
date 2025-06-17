//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
struct ParticipantsInCallView<Factory: ViewFactory>: View {

    struct ParticipantInCall: Identifiable {
        let id: String
        let user: User
    }

    var viewFactory: Factory
    var callParticipants: [User]

    init(
        viewFactory: Factory,
        callParticipants: [User]
    ) {
        self.viewFactory = viewFactory
        self.callParticipants = callParticipants
    }

    var participantsInCall: [ParticipantInCall] {
        var result = [ParticipantInCall]()
        for (index, participant) in callParticipants.enumerated() {
            let id = "\(index)-\(participant.id)"
            let participant = ParticipantInCall(id: id, user: participant)
            result.append(participant)
        }
        return result
    }
    
    private let viewSize: CGFloat = 64
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(participantsInCall) { participant in
                    VStack {
                        viewFactory.makeUserAvatar(
                            participant.user,
                            with: .init(size: 40) {
                                AnyView(
                                    CircledTitleView(
                                        title: participant.user.name.isEmpty ? participant.user
                                            .id : String(participant.user.name.uppercased().first!),
                                        size: 40
                                    )
                                )
                            }
                        )

                        Text(participant.user.name)
                            .font(.caption)
                    }
                    .frame(width: viewSize, height: viewSize)
                }
            }
        }
        .frame(height: viewSize)
    }
}
