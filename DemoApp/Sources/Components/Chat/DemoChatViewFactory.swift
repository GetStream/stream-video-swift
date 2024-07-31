//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatSwiftUI
import class StreamVideoSwiftUI.CallViewModel
import SwiftUI

final class DemoChatViewFactory {

    @Injected(\.chatClient) var chatClient: ChatClient

    private init() {}

    @MainActor static let shared = DemoChatViewFactory()

    @MainActor func makeReactionsOverlayView(
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

#if swift(>=6.0)
extension DemoChatViewFactory: @preconcurrency ViewFactory {}
#else
extension DemoChatViewFactory: ViewFactory {}
#endif
