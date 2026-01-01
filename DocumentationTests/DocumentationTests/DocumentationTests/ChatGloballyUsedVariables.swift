//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatSwiftUI

final class ChatViewFactory: ViewFactory {
    var chatClient: ChatClient

    init(chatClient: ChatClient) {
        self.chatClient = chatClient
    }

    static let shared = ChatViewFactory(chatClient: .init(config: .init(apiKey: .init(""))))
}
