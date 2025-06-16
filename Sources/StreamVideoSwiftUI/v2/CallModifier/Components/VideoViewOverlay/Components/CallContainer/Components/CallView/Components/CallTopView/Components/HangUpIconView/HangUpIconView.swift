//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying the hang-up button for a call.
public struct HangUpIconView: View {
    var size: CGFloat
    var actionHandler: () -> Void

    /// Initializes the hang-up icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the hang-up icon.
    ///   - size: The size of the hang-up icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.init(
            size: size,
            actionHandler: {
                [weak viewModel] in viewModel?.hangUp()
            }
        )
    }

    public init(
        size: CGFloat = 44,
        actionHandler: @escaping () -> Void
    ) {
        self.size = size
        self.actionHandler = actionHandler
    }
    
    public var body: some View {
        StatelessHangUpIconView(size: size, actionHandler: actionHandler)
    }
}
