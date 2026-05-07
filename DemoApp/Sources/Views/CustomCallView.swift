//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideoSwiftUI
import SwiftUI

struct CustomCallView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        StreamVideoSwiftUI.CallView(viewFactory: viewFactory, viewModel: viewModel)
            .modifier(DemoSpeakingWhileMutedViewModifier(viewModel: viewModel))
    }
}
