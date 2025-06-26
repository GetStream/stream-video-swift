//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct CallParticipantsInfoView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    @StateObject var viewModel: CallParticipantsInfoViewModel

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        callViewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        _viewModel = StateObject(
            wrappedValue: CallParticipantsInfoViewModel(callViewModel)
        )
    }
    
    public var body: some View {
        CallParticipantsView(
            viewFactory: viewFactory,
            viewModel: viewModel
        )
    }
}
