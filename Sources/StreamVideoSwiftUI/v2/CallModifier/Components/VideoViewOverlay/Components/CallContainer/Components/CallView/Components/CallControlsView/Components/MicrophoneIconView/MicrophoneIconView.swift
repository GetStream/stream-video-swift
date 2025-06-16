//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying the microphone toggle button for a call.
public struct MicrophoneIconView: View {

    var viewModel: CallViewModel
    var size: CGFloat
    @State var hasCapability: Bool
    @State var isEnabled: Bool

    /// Initializes the microphone icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the microphone icon.
    ///   - size: The size of the microphone icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
        hasCapability = viewModel.call?.state.ownCapabilities.contains(.sendAudio) ?? false
        isEnabled = viewModel.call?.state.callSettings.audioOn ?? false
    }

    public var body: some View {
        Group {
            if hasCapability {
                StatelessMicrophoneIconView(
                    isEnabled: isEnabled,
                    actionHandler: { [weak viewModel] in viewModel?.toggleMicrophoneEnabled() }
                )
                .equatable()
                .onReceive(
                    viewModel
                        .call?
                        .state
                        .$callSettings
                        .map(\.audioOn)
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
                .map { $0.contains(.sendAudio) }
                .removeDuplicates()
        ) { hasCapability = $0 }
    }
}
