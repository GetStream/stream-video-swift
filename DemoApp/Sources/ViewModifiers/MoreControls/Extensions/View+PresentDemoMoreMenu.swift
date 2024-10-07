//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

extension View {

    @ViewBuilder
    func presentsMoreControls(viewModel: CallViewModel) -> some View {
        modifier(DemoMoreControlsViewModifier(viewModel: viewModel))
    }
}
