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

struct StreamChatWrapper {

    let chatClient: ChatClient
    let streamChatUI: StreamChat

    init(_ user: User, token: String) {
        let chatClient = ChatClient(config: .init(apiKeyString: AppEnvironment.apiKey.rawValue))

        self.chatClient = chatClient
        self.streamChatUI = .init(chatClient: chatClient)

        StreamChatProviderKey.currentValue = self

        chatClient.connectUser(
            userInfo: .init(
                id: user.id,
                name: user.name,
                imageURL: user.imageURL
            )) { result in result(.success(.init(stringLiteral: token))) }
    }
}

/// Returns the current value for the `StreamVideo` instance.
struct StreamChatProviderKey: StreamChatSwiftUI.InjectionKey {
    static var currentValue: StreamChatWrapper?
}

extension StreamChatSwiftUI.InjectedValues {
    /// Provides access to the `StreamVideo` instance in the views and view models.
    var streamChatWrapper: StreamChatWrapper? {
        get {
            Self[StreamChatProviderKey.self]
        }
        set {
            Self[StreamChatProviderKey.self] = newValue
        }
    }
}

@MainActor
final class StreamChatVideoViewModel: ObservableObject, ChatChannelControllerDelegate {

    @StreamChatSwiftUI.Injected(\.streamChatWrapper) var chatWrapper

    private var callUpdateCancellable: AnyCancellable?
    @Published private(set) var channelController: ChatChannelController? {
        didSet { setUpChannelController() }
    }

    @Published var isChatVisible = false
    @Published var unreadCount = 0

    private var channelId: ChannelId?
    var isChatEnabled: Bool { chatWrapper != nil }

    init(_ callViewModel: CallViewModel) {
        self.callUpdateCancellable = callViewModel.$call.sink { [weak self] newCall in
            guard let newCall, let self else {
                self?.channelController = nil
                return
            }

            let channelId = ChannelId(type: .custom("videocall"), id: newCall.callId)
            self.channelId = channelId
            self.channelController = self.chatWrapper?
                .chatClient
                .channelController(for: channelId)
        }
    }

    private func setUpChannelController() {
        guard let channelController else { return }
        channelController.synchronize()
        channelController.delegate = self
    }

    nonisolated func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        Task {
            await MainActor.run {
                self.unreadCount = channel.item.unreadCount.messages
            }
        }
    }

    func markAsRead() {
        channelController?.markRead { error in
            if let error {
                log.error(error)
            }
        }
        unreadCount = 0
    }

    func channelDisappeared() {
        guard let channelId = channelId else { return }
        self.channelController = self.chatWrapper?
            .chatClient
            .channelController(for: channelId)
    }
}
