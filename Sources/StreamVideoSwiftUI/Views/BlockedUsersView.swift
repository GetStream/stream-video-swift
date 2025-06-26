//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct BlockedUsersView: View {
    
    var viewModel: CallParticipantsInfoViewModel
    var blockedUsers: [User]

    var body: some View {
        HStack {
            VStack(alignment: .leading) {

                Text(L10n.Call.Participants.blocked)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 8)

                ForEach(blockedUsers) { blockedUser in
                    Text(blockedUser.id)
                        .contextMenu {
                            ForEach(viewModel.unblockActions(for: blockedUser)) { menuAction in
                                Button {
                                    menuAction.action(blockedUser.id)
                                } label: {
                                    HStack {
                                        Image(systemName: menuAction.iconName)
                                        Text(menuAction.title)
                                        Spacer()
                                    }
                                }
                            }
                        }
                }
            }
            Spacer()
        }
    }
}
