//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

/// A view displaying the toggle camera position button for a call.
public struct ToggleCameraIconView: View {

    @Injected(\.images) var images

    weak var call: Call?
    var size: CGFloat
    var capabilityPublisher: AnyPublisher<Bool, Never>?
    var actionHandler: () -> Void

    @State var hasRequiredCapability: Bool

    /// Initializes the toggle camera icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the toggle camera icon.
    ///   - size: The size of the toggle camera icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        call = viewModel.call
        self.size = size
        hasRequiredCapability = viewModel.call?.state.ownCapabilities.contains(.sendVideo) ?? false
        capabilityPublisher = viewModel.call?.state.$ownCapabilities.compactMap { $0.contains(.sendVideo) }.eraseToAnyPublisher()
        actionHandler = { [weak viewModel] in viewModel?.toggleCameraPosition() }
    }

    public var body: some View {
        if let call {
            content
                .id(call.cId + "_" + "\(type(of: self))")
                .onReceive(capabilityPublisher) { hasRequiredCapability = $0 }
                .debugViewRendering()
        }
    }

    @ViewBuilder
    var content: some View {
        if hasRequiredCapability {
            StatelessToggleCameraIconView(
                call: call,
                actionHandler: actionHandler
            )
        }
    }
}
