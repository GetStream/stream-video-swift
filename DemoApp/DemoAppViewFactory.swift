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
        if UIDevice.current.userInterfaceIdiom == .pad {
            CallControlsView_iPad(viewModel: viewModel)
        } else {
            DefaultViewFactory.shared.makeCallView(viewModel: viewModel)
        }
    }
}
