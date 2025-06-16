//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying the toggle camera position button for a call.
public struct ToggleCameraIconView: View {
    @Injected(\.images) var images

    var viewModel: CallViewModel
    var cameraPosition: CameraPosition
    var size: CGFloat
    var actionHandler: () -> Void

    @State var hasVideoCapability: Bool

    /// Initializes the toggle camera icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the toggle camera icon.
    ///   - size: The size of the toggle camera icon (default is 44).
    public init(
        viewModel: CallViewModel,
        size: CGFloat = 44
    ) {
        self.viewModel = viewModel
        cameraPosition = viewModel.call?.state.callSettings.cameraPosition ?? .front
        self.size = size
        hasVideoCapability = viewModel.call?.state.ownCapabilities.contains(.sendVideo) ?? false
        actionHandler = { [weak viewModel] in viewModel?.toggleCameraPosition() }
    }

    public var body: some View {
        Group {
            if hasVideoCapability {
                StatelessToggleCameraIconView(
                    cameraPosition: cameraPosition,
                    size: size,
                    actionHandler: actionHandler
                )
            }
        }
        .onReceive(viewModel.call?.state.$ownCapabilities.map { $0.contains(.sendVideo) }.removeDuplicates()) {
            hasVideoCapability = $0
        }
    }
}
