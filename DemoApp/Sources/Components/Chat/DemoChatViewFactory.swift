//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatSwiftUI
import class StreamVideoSwiftUI.CallViewModel
import SwiftUI

@MainActor
final class DemoChatViewFactory: @MainActor ViewFactory {

    @Injected(\.chatClient) var chatClient: ChatClient

    private init() {}

    static let shared = DemoChatViewFactory()
    
    public var styles = RegularStyles()

    func makeReactionsOverlayView(options: ReactionsOverlayViewOptions) -> some View {
        DemoReactionsOverlayView(
            factory: self,
            channel: options.channel,
            currentSnapshot: options.currentSnapshot,
            messageDisplayInfo: options.messageDisplayInfo,
            onBackgroundTap: options.onBackgroundTap,
            onActionExecuted: options.onActionExecuted
        )
    }
}
