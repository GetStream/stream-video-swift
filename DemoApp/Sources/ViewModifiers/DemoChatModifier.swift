//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct ChatModifier: ViewModifier {

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject var chatViewModel: DemoChatViewModel

    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: $chatViewModel.isChatVisible
            ) {
                if let channelController = chatViewModel.channelController {
                    ChatView(
                        channelController: channelController,
                        chatViewModel: chatViewModel,
                        callViewModel: viewModel
                    )
                    .withModalNavigationBar(title: "Chat") { chatViewModel.isChatVisible = false }
                    .withDragIndicator()
                }
            }
    }
}

extension View {

    @ViewBuilder
    func chat(viewModel: CallViewModel, chatViewModel: DemoChatViewModel?) -> some View {
        if let chatViewModel {
            modifier(ChatModifier(viewModel: viewModel, chatViewModel: chatViewModel))
        } else {
            self
        }
    }
}
