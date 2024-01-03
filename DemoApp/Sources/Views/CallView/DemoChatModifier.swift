//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideoSwiftUI

struct ChatModifier: ViewModifier {

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject var chatViewModel: DemoChatViewModel

    func body(content: Content) -> some View {
        content
            .halfSheetIfAvailable(
                isPresented: $chatViewModel.isChatVisible,
                onDismiss: {}
            ) {
                if let channelController = chatViewModel.channelController {
                    VStack {
                        ChatControlsHeader(viewModel: viewModel)
                        ChatView(
                            channelController: channelController,
                            chatViewModel: chatViewModel,
                            callViewModel: viewModel
                        )
                    }
                }
            }
    }
}

extension View {

    @ViewBuilder
    func chat(viewModel: CallViewModel, chatViewModel: DemoChatViewModel?) -> some View {
        if let chatViewModel {
            self.modifier(ChatModifier(viewModel: viewModel, chatViewModel: chatViewModel))
        } else {
            self
        }
    }
}
