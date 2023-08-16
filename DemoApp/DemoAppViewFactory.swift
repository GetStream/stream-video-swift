//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

class DemoAppViewFactory: ViewFactory {
    
    static let shared = DemoAppViewFactory()
    
    func makeWaitingLocalUserView(viewModel: CallViewModel) -> some View {
        CustomWaitingLocalUserView(viewModel: viewModel, viewFactory: self)
    }
    
    @ViewBuilder
    func makeCallControlsView(viewModel: CallViewModel) -> some View {
#if targetEnvironment(simulator)
        DefaultViewFactory.shared.makeCallControlsView(viewModel: viewModel)
#else
        DemoAppCallControlsView(viewModel: viewModel)
#endif
    }
    
    func makeCallTopView(viewModel: CallViewModel) -> some View {
        CustomCallTopView(viewModel: viewModel)
    }
}
