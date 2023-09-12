//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
@preconcurrency import StreamChat
import StreamChatSwiftUI
import Combine
import StreamVideoSwiftUI
import SwiftUI

@MainActor
final class DemoChatViewModel: ObservableObject, ChatChannelControllerDelegate {

    @StreamChatSwiftUI.Injected(\.chatWrapper) var chatWrapper

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
