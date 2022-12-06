//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ScreenSharingView: View {
    
    @StateObject var viewModel: CallViewModel
    var screenSharing: ScreensharingSession
    var availableSize: CGSize
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text("\(screenSharing.participant.name) presenting")
                .foregroundColor(.white)
                .padding()
                .padding(.top, 40)
            VideoRendererView(
                id: screenSharing.participant.id,
                size: availableSize,
                contentMode: .scaleAspectFit
            ) { view in
                if let track = screenSharing.participant.screenshareTrack {
                    log.debug("adding screensharing track to a view \(view)")
                    view.add(track: track)
                }
            }
        }
        .background(Color.black)
    }
}
