//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import LiveKit
import StreamVideo
import SwiftUI

struct StreamVideoView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    private var track: StreamVideoTrack
    
    @State var trackStats: TrackStats?
    
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    public init(_ track: StreamVideoTrack) {
        self.track = track
    }
    
    var body: some View {
        SwiftUIVideoView(
            track,
            layoutMode: .fill,
            mirrorMode: .auto,
            debugMode: false,
            trackStats: $trackStats
        )
        .onReceive(timer) { _ in
            if let trackStats = trackStats {
                log.debug("Reported call stats \(trackStats)")
            }
        }
    }
}
