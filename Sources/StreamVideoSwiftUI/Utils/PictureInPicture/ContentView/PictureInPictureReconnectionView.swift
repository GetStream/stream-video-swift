//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct PictureInPictureReconnectionView: View {

    @Injected(\.colors) private var colors

    var body: some View {
        VStack {
            Text(L10n.Call.Current.reconnecting)
                .applyCallingStyle()
                .padding()
                .accessibility(identifier: "reconnectingMessage")
            CallingIndicator()
        }
        .padding()
        .background(
            Color(colors.callBackground).opacity(0.7).edgesIgnoringSafeArea(.all)
        )
        .cornerRadius(16)
    }
}
