//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying the hang-up button for a call.
public struct HangUpIconView: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors

    var viewModel: CallViewModel
    let size: CGFloat

    /// Initializes the hang-up icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the hang-up icon.
    ///   - size: The size of the hang-up icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
    }

    public var body: some View {
        StatelessHangUpIconView(call: viewModel.call) { [weak viewModel] in
            viewModel?.hangUp()
        }
        .debugViewRendering()
    }
}
