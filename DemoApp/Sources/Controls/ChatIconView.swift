//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct ChatIconView: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors

    var viewModel: DemoChatViewModel
    let size: CGFloat

    @State var isActive: Bool
    var isActivePublisher: AnyPublisher<Bool, Never>

    @State var unreadCount: Int
    var unreadCountPublisher: AnyPublisher<Int, Never>

    init(viewModel: DemoChatViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size

        isActive = viewModel.isChatVisible
        isActivePublisher = viewModel
            .$isChatVisible
            .removeDuplicates()
            .eraseToAnyPublisher()

        unreadCount = viewModel.unreadCount
        unreadCountPublisher = viewModel
            .$unreadCount
            .removeDuplicates()
            .eraseToAnyPublisher()
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
                    iconStyle: isActive ? .secondaryActive : .secondary
                ).overlay(overlayView)
            }
        )
        .accessibility(identifier: "chatToggle")
        .onReceive(isActivePublisher) { isActive = $0 }
        .onReceive(unreadCountPublisher) { unreadCount = $0 }
    }

    @ViewBuilder
    var overlayView: some View {
        if unreadCount > 0 {
            ControlBadgeView("\(unreadCount)")
        } else {
            EmptyView()
        }
    }
}
