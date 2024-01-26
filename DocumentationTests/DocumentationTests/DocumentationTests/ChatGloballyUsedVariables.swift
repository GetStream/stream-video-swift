import StreamChatSwiftUI
import StreamChat

final class ChatViewFactory: ViewFactory {
    var chatClient: ChatClient

    init(chatClient: ChatClient) {
        self.chatClient = chatClient
    }

    static let shared = ChatViewFactory(chatClient: .init(config: .init(apiKey: .init(""))))
}
