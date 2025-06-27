//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct SilentMicrophoneIndicator: View {

    @Injected(\.colors) var colors

    var viewModel: LobbyViewModel

    @State var isSilent: Bool

    init(viewModel: LobbyViewModel) {
        self.viewModel = viewModel
        isSilent = viewModel.isSilent
    }

    var body: some View {
        contentView
            .onReceive(viewModel.$isSilent.removeDuplicates()) { isSilent = $0 }
    }

    @ViewBuilder
    var contentView: some View {
        if isSilent {
            Text(L10n.WaitingRoom.Mic.notWorking)
                .font(.caption)
                .foregroundColor(colors.text)
        } else {
            EmptyView()
        }
    }
}
