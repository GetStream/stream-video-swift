//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatSwiftUI
import StreamChat
import SwiftUI
import class StreamVideoSwiftUI.CallViewModel

final class StreamChatViewFactory: ViewFactory {

    @Injected(\.chatClient) var chatClient: ChatClient

    private init() {}

    static let shared = StreamChatViewFactory()

    func makeReactionsOverlayView(
        channel: ChatChannel,
        currentSnapshot: UIImage,
        messageDisplayInfo: MessageDisplayInfo,
        onBackgroundTap: @escaping () -> Void,
        onActionExecuted: @escaping (MessageActionInfo) -> Void
    ) -> some View {
        DemoReactionsOverlayView(
            factory: self,
            channel: channel,
            currentSnapshot: currentSnapshot,
            messageDisplayInfo: messageDisplayInfo,
            onBackgroundTap: onBackgroundTap,
            onActionExecuted: onActionExecuted
        )
    }
}
