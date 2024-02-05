//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideoSwiftUI
import SwiftUI

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
            modifier(ChatModifier(viewModel: viewModel, chatViewModel: chatViewModel))
        } else {
            self
        }
    }
}
