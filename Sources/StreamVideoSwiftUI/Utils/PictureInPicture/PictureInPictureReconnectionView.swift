//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// Displays a reconnection state in the Picture-in-Picture window.
///
/// Shows a reconnection message and loading indicator while attempting to restore
/// the connection to the video call.
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
