//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct ScreenshareIconView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    var viewModel: CallViewModel
    var size: CGFloat
    var capabilityPublisher: AnyPublisher<Bool, Never>?
    var publisher: AnyPublisher<Bool, Never>?
    var actionHandler: () -> Void

    @State var hasRequiredCapability: Bool
    @State var isEnabled: Bool

    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size

        hasRequiredCapability = viewModel
            .call?
            .state
            .ownCapabilities
            .contains(.screenshare) ?? false
        capabilityPublisher = viewModel
            .call?
            .state
            .$ownCapabilities
            .compactMap { $0.contains(.screenshare) }
            .eraseToAnyPublisher()

        isEnabled = viewModel.call?.state.isCurrentUserScreensharing ?? false
        publisher = viewModel
            .call?
            .state
            .$isCurrentUserScreensharing
            .removeDuplicates()
            .eraseToAnyPublisher()
        actionHandler = { [weak viewModel] in viewModel?.startScreensharing(type: .inApp) }
    }
    
    public var body: some View {
        contentView
            .onReceive(capabilityPublisher) { hasRequiredCapability = $0 }
            .onReceive(publisher) { isEnabled = $0 }
            .debugViewRendering()
    }

    @ViewBuilder
    var contentView: some View {
        if hasRequiredCapability {
            Button {
                actionHandler()
            } label: {
                CallIconView(
                    icon: images.screenshareIcon,
                    size: size,
                    iconStyle: isEnabled ? .primary : .transparent
                )
            }
        }
    }
}
