//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

/// A view displaying the microphone toggle button for a call.
public struct MicrophoneIconView: View {

    weak var call: Call?
    var size: CGFloat
    var capabilityPublisher: AnyPublisher<Bool, Never>?
    var actionHandler: () -> Void

    @State var hasRequiredCapability: Bool

    /// Initializes the microphone icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the microphone icon.
    ///   - size: The size of the microphone icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        call = viewModel.call
        self.size = size
        hasRequiredCapability = viewModel.call?.state.ownCapabilities.contains(.sendAudio) ?? false
        capabilityPublisher = viewModel.call?.state.$ownCapabilities.compactMap { $0.contains(.sendAudio) }.eraseToAnyPublisher()
        actionHandler = { [weak viewModel] in viewModel?.toggleMicrophoneEnabled() }
    }

    public var body: some View {
        if hasRequiredCapability {
            StatelessMicrophoneIconView(
                call: call,
                actionHandler: actionHandler
            )
            .debugViewRendering()
        }
    }
}
