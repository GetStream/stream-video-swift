//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct JoinCallView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors

    var viewFactory: Factory
    var callId: String
    var callType: String
    var callParticipants: [User]
    var onJoinCallTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(waitingRoomDescription)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(identifier: "callParticipantsCount")
                .streamAccessibility(value: "\(callParticipants.count)")
            
            if #available(iOS 14, *) {
                if !callParticipants.isEmpty {
                    ParticipantsInCallView(
                        viewFactory: viewFactory,
                        callParticipants: callParticipants
                    )
                }
            }
            
            Button {
                onJoinCallTap()
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
    }
    
    private var waitingRoomDescription: String {
        "\(L10n.WaitingRoom.description) \(L10n.WaitingRoom.numberOfParticipants(callParticipants.count))"
    }
    
    private var otherParticipantsCount: Int {
        let count = callParticipants.count - 1
        if count > 0 {
            return count
        } else {
            return 0
        }
    }
}
