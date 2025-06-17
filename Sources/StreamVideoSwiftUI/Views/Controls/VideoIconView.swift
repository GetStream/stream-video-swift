//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

/// A view displaying the video toggle button for a call.
public struct VideoIconView: View {

    weak var call: Call?
    var size: CGFloat
    var capabilityPublisher: AnyPublisher<Bool, Never>?
    var actionHandler: () -> Void

    @State var hasRequiredCapability: Bool

    /// Initializes the video icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the video icon.
    ///   - size: The size of the video icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        call = viewModel.call
        self.size = size
        hasRequiredCapability = viewModel.call?.state.ownCapabilities.contains(.sendVideo) ?? false
        capabilityPublisher = viewModel.call?.state.$ownCapabilities.compactMap { $0.contains(.sendVideo) }.eraseToAnyPublisher()
        actionHandler = { [weak viewModel] in viewModel?.toggleCameraEnabled() }
    }

    public var body: some View {
        if hasRequiredCapability {
            StatelessVideoIconView(
                call: call,
                actionHandler: actionHandler
            )
            .debugViewRendering()
        }
    }
}
