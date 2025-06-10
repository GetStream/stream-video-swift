//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying the video toggle button for a call.
public struct VideoIconView: View, Equatable {

    var isEnabled: Bool
    var size: CGFloat
    var actionHandler: () -> Void

    /// Initializes the video icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the video icon.
    ///   - size: The size of the video icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.init(
            isEnabled: viewModel.call?.state.callSettings.videoOn ?? false,
            size: size,
            actionHandler: { [weak viewModel] in viewModel?.toggleCameraEnabled() }
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
        lhs: VideoIconView,
        rhs: VideoIconView
    ) -> Bool {
        lhs.isEnabled == rhs.isEnabled
            && lhs.size == rhs.size
    }

    public var body: some View {
        StatelessVideoIconView(
            isEnabled: isEnabled,
            actionHandler: actionHandler
        )
        .equatable()
    }
}
