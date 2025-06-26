//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

/// A view displaying the audio output toggle button for a call.
public struct AudioOutputIconView: View {

    weak var call: Call?
    var size: CGFloat
    var actionHandler: () -> Void

    /// Initializes the audio output icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the audio output icon.
    ///   - size: The size of the audio output icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        call = viewModel.call
        self.size = size
        actionHandler = { [weak viewModel] in viewModel?.toggleAudioOutput() }
    }

    public var body: some View {
        StatelessAudioOutputIconView(
            call: call,
            actionHandler: actionHandler
        )
        .debugViewRendering()
    }
}
