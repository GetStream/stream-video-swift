//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying the audio output toggle button for a call.
public struct AudioOutputIconView: View, Equatable {

    var isEnabled: Bool
    var size: CGFloat
    var actionHandler: () -> Void

    /// Initializes the audio output icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the audio output icon.
    ///   - size: The size of the audio output icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        isEnabled = viewModel.call?.state.callSettings.audioOutputOn ?? true
        self.size = size
        actionHandler = { [weak viewModel] in viewModel?.toggleAudioOutput() }
    }

    nonisolated public static func == (
        lhs: AudioOutputIconView,
        rhs: AudioOutputIconView
    ) -> Bool {
        lhs.isEnabled == rhs.isEnabled
            && lhs.size == rhs.size
    }

    public var body: some View {
        StatelessAudioOutputIconView(
            isEnabled: isEnabled,
            actionHandler: actionHandler
        )
        .equatable()
    }
}
