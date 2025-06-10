//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying the toggle camera position button for a call.
public struct ToggleCameraIconView: View, @preconcurrency Equatable {
    @Injected(\.images) var images

    var cameraPosition: CameraPosition
    let size: CGFloat
    var actionHandler: () -> Void

    /// Initializes the toggle camera icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the toggle camera icon.
    ///   - size: The size of the toggle camera icon (default is 44).
    public init(
        viewModel: CallViewModel,
        size: CGFloat = 44
    ) {
        cameraPosition = viewModel.call?.state.callSettings.cameraPosition ?? .front
        self.size = size
        actionHandler = { [weak viewModel] in
            viewModel?.toggleCameraPosition()
        }
    }

    init(
        cameraPosition: CameraPosition,
        size: CGFloat = 44,
        actionHandler: @escaping () -> Void
    ) {
        self.cameraPosition = cameraPosition
        self.size = size
        self.actionHandler = actionHandler
    }

    public static func == (
        lhs: ToggleCameraIconView,
        rhs: ToggleCameraIconView
    ) -> Bool {
        lhs.cameraPosition == rhs.cameraPosition
            && lhs.size == rhs.size
    }

    public var body: some View {
        StatelessToggleCameraIconView(
            cameraPosition: cameraPosition,
            size: size,
            actionHandler: actionHandler
        )
    }
}
