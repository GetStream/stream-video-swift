//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying the video toggle button for a call.
public struct VideoIconView: View {

    var viewModel: CallViewModel
    var size: CGFloat
    @State var hasCapability: Bool
    @State var isEnabled: Bool

    /// Initializes the video icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the video icon.
    ///   - size: The size of the video icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
        hasCapability = viewModel.call?.state.ownCapabilities.contains(.sendVideo) ?? false
        isEnabled = viewModel.call?.state.callSettings.videoOn ?? false
    }

    public var body: some View {
        Group {
            if hasCapability {
                StatelessVideoIconView(
                    isEnabled: isEnabled,
                    actionHandler: { [weak viewModel] in viewModel?.toggleCameraEnabled() }
                )
                .equatable()
                .onReceive(
                    viewModel
                        .call?
                        .state
                        .$callSettings
                        .map(\.videoOn)
                        .removeDuplicates()
                ) { isEnabled = $0 }
            } else {
                EmptyView()
            }
        }
        .onReceive(
            viewModel
                .call?
                .state
                .$ownCapabilities
                .map { $0.contains(.sendVideo) }
                .removeDuplicates()
        ) { hasCapability = $0 }
    }
}
