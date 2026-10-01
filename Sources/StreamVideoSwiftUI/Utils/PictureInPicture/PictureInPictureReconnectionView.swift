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

    var body: some View {
        VStack(spacing: layout.spacingXs) {
            Text(L10n.Call.Current.reconnecting)
                .font(fonts.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(colors.textOnAccent))
                .padding(layout.spacingMd)
                .accessibility(identifier: "reconnectingMessage")
            CallingIndicator()
        }
        .padding(layout.spacingMd)
        .background(
            Color(colors.backgroundCoreOverlayDarkStrong).edgesIgnoringSafeArea(.all)
        )
        .cornerRadius(layout.radiusXl)
    }
}
