//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallTopView: View {

    var viewModel: CallViewModel

    @State var isLivestream: Bool
    var isLivestreamPublisher: AnyPublisher<Bool, Never>?

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel

        isLivestream = (viewModel.call?.callType == .livestream)
        isLivestreamPublisher = viewModel
            .$call
            .map { $0?.callType == .livestream }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var body: some View {
        contentView
            .onReceive(isLivestreamPublisher) { isLivestream = $0 }
    }

    @ViewBuilder
    var contentView: some View {
        if isLivestream {
            DemoLivestreamTopView(viewModel: viewModel)
        } else {
            DefaultViewFactory
                .shared
                .makeCallTopView(viewModel: viewModel)
        }
    }
}
