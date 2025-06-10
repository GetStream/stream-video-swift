//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatSwiftUI
import SwiftUI

struct ChatView: View {

    var channelController: ChatChannelController
    var chatViewModel: DemoChatViewModel

    var body: some View {
        NavigationView {
            ChatChannelView(
                viewFactory: DemoChatViewFactory.shared,
                channelController: channelController
            )
            .onAppear { chatViewModel.markAsRead() }
            .onDisappear { chatViewModel.channelDisappeared() }
            .navigationBarHidden(true)
        }
    }
}
