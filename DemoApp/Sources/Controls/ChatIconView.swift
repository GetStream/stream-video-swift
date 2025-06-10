//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideoSwiftUI
import SwiftUI

struct ChatIconView: View, Equatable {
    @ObservedObject var viewModel: DemoChatViewModel
    let size: CGFloat

    init(viewModel: DemoChatViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
    }

    static func == (
        lhs: ChatIconView,
        rhs: ChatIconView
    ) -> Bool {
        lhs.viewModel.isChatVisible == rhs.viewModel.isChatVisible
            && lhs.viewModel.isChatEnabled == rhs.viewModel.isChatEnabled
            && lhs.size == rhs.size
            && lhs.viewModel.unreadCount == rhs.viewModel.unreadCount
    }

    var body: some View {
        Button(
            action: {
                viewModel.isChatVisible.toggle()
            },
            label: {
                CallIconView(
                    icon: .init(systemName: "bubble.left.and.bubble.right.fill"),
                    size: size,
                    iconStyle: viewModel.isChatVisible ? .secondaryActive : .secondary
                ).overlay(
                    ControlBadgeView("\(viewModel.unreadCount)")
                        .equatable()
                        .opacity(viewModel.unreadCount > 0 ? 1 : 0)
                )
            }
        )
        .accessibility(identifier: "chatToggle")
    }
}
