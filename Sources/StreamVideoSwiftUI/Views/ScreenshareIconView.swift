//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ScreenshareIconView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
        Button {
            viewModel.startScreensharing(type: .inApp)
        } label: {
            CallIconView(
                icon: images.screenshareIcon,
                size: size,
                iconStyle: (viewModel.call?.state.isCurrentUserScreensharing == false ? .transparent : .primary)
            )
        }
        .debugViewRendering()
    }
}
