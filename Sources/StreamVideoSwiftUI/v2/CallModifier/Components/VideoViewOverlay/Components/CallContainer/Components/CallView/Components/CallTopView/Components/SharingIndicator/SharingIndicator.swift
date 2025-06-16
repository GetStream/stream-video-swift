//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct SharingIndicator: View {

    var viewModel: CallViewModel
    @State var isVisible: Bool

    public init(
        viewModel: CallViewModel,
    ) {
        self.viewModel = viewModel
        isVisible = viewModel.call?.state.isCurrentUserScreensharing ?? false
    }

    public var body: some View {
        Group {
            if isVisible {
                content
            } else {
                EmptyView()
            }
        }
        .onReceive(viewModel.call?.state.$isCurrentUserScreensharing.removeDuplicates()) { isVisible = $0 }
    }

    @ViewBuilder
    private var content: some View {
        HStack {
            Text(L10n.Call.Current.sharing)
                .font(.headline)
            Divider()

            Button {
                [weak viewModel] in viewModel?.stopScreensharing()
            } label: {
                Text(L10n.Call.Current.stopSharing)
                    .font(.headline)
            }

            Button {
                isVisible = true
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 14)
            }
            .padding(.leading, 4)
        }
        .padding(.all, 8)
        .modifier(ShadowViewModifier())
    }
}
