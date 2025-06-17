//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct CallParticipantsInfoView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    @StateObject var viewModel: CallParticipantsInfoViewModel
    @ObservedObject var callViewModel: CallViewModel

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        callViewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.callViewModel = callViewModel
        _viewModel = StateObject(
            wrappedValue: CallParticipantsInfoViewModel(
                call: callViewModel.call
            )
        )
    }
    
    public var body: some View {
        CallParticipantsView(
            viewFactory: viewFactory,
            viewModel: viewModel,
            callViewModel: callViewModel
        )
    }
}
