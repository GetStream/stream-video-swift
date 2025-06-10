//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct ChatModifier: ViewModifier {

    @Injected(\.images) var images
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors

    @ObservedObject var chatViewModel: DemoChatViewModel

    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: $chatViewModel.isChatVisible
            ) {
                if let channelController = chatViewModel.channelController {
                    ChatView(
                        channelController: channelController,
                        chatViewModel: chatViewModel
                    )
                    .withModalNavigationBar(title: "Chat") { chatViewModel.isChatVisible = false }
                    .withDragIndicator()
                }
            }
    }
}

extension View {

    @ViewBuilder
    func chat(chatViewModel: DemoChatViewModel?) -> some View {
        if let chatViewModel {
            modifier(ChatModifier(chatViewModel: chatViewModel))
        } else {
            self
        }
    }
}
