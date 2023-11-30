//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import class StreamChat.ChatClient
import class StreamChat.ChatChannelController
import struct StreamChat.ChannelId
import protocol StreamChat.ChatChannelControllerDelegate
import enum StreamChat.EntityChange
import struct StreamChat.ChatChannel
import StreamVideo
import StreamChatSwiftUI
import Combine
import StreamVideoSwiftUI

struct DemoChatAdapter {

    let chatClient: ChatClient
    let streamChatUI: StreamChat

    @MainActor
    init(_ user: User, token: String) {
        let chatClient = ChatClient(config: .init(apiKeyString: AppState.shared.apiKey))

        self.chatClient = chatClient
        self.streamChatUI = .init(chatClient: chatClient)

        InjectionKey.currentValue = self

        chatClient.connectUser(
            userInfo: .init(
                id: user.id,
                name: user.name,
                imageURL: user.imageURL
            )) { result in result(.success(.init(stringLiteral: token))) }
    }
}

extension DemoChatAdapter {
    /// Returns the current value for the `StreamVideo` instance.
    struct InjectionKey: StreamChatSwiftUI.InjectionKey {
        static var currentValue: DemoChatAdapter?
    }
}

extension StreamChatSwiftUI.InjectedValues {
    /// Provides access to the `StreamVideo` instance in the views and view models.
    var chatWrapper: DemoChatAdapter? {
        get {
            Self[DemoChatAdapter.InjectionKey.self]
        }
        set {
            Self[DemoChatAdapter.InjectionKey.self] = newValue
        }
    }
}
