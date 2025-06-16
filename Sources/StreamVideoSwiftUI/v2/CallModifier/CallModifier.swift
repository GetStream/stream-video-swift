//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallModifier<Factory: ViewFactory>: ViewModifier {
    
    var viewFactory: Factory
    var viewModel: CallViewModel

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }
    
    public func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            VideoViewOverlay(
                rootView: content,
                viewFactory: viewFactory,
                viewModel: viewModel
            )
        } else {
            VideoViewOverlay_iOS13(
                rootView: content,
                viewFactory: viewFactory,
                viewModel: viewModel
            )
        }
    }
}

extension CallModifier where Factory == DefaultViewFactory {

    public init(viewModel: CallViewModel) {
        self.init(viewFactory: DefaultViewFactory.shared, viewModel: viewModel)
    }
}
