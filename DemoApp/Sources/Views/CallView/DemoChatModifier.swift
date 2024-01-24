//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct ChatModifier: ViewModifier {

    @Injected(\.images) var images
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject var chatViewModel: DemoChatViewModel

    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: $chatViewModel.isChatVisible
            ) {
                if let channelController = chatViewModel.channelController {
                    VStack(spacing: 0) {
                        VStack(alignment: .center) {
                            DragHandleView()
                                .padding(.top)
                        }.frame(maxWidth: .infinity)

                        HStack {
                            Text("Chat")
                                .font(fonts.title3)
                                .fontWeight(.medium)

                            Spacer()

                            ModalButton(image: images.xmark) {
                                chatViewModel.isChatVisible = false
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.bottom, 24)
                        .padding(.top)
                        .padding(.horizontal)
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
