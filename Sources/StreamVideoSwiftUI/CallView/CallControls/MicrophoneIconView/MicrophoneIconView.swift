//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying the microphone toggle button for a call.
public struct MicrophoneIconView: View, Equatable {

    var isEnabled: Bool
    var size: CGFloat
    var actionHandler: () -> Void

    /// Initializes the microphone icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the microphone icon.
    ///   - size: The size of the microphone icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.init(
            isEnabled: viewModel.call?.state.callSettings.audioOn ?? false,
            size: size,
            actionHandler: { [weak viewModel] in viewModel?.toggleMicrophoneEnabled() }
        )
    }

    public init(
        isEnabled: Bool,
        size: CGFloat = 44,
        actionHandler: @escaping () -> Void
    ) {
        self.isEnabled = isEnabled
        self.size = size
        self.actionHandler = actionHandler
    }

    nonisolated public static func == (
        lhs: MicrophoneIconView,
        rhs: MicrophoneIconView
    ) -> Bool {
        lhs.isEnabled == rhs.isEnabled
            && lhs.size == rhs.size
    }

    public var body: some View {
        StatelessMicrophoneIconView(
            isEnabled: isEnabled,
            actionHandler: actionHandler
        )
        .equatable()
    }
}
