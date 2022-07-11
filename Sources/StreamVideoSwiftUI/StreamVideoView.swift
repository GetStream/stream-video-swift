//
//  VideoView.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 8.7.22.
//

import SwiftUI
import Combine
import StreamVideo
import LiveKit

struct StreamVideoView: View {
    
    private var track: StreamVideoTrack
    
    public init(_ track: StreamVideoTrack) {
        self.track = track
    }
    
    var body: some View {
        SwiftUIVideoView(
            track,
            layoutMode: .fill,
            mirrorMode: .auto,
            debugMode: false
        )
    }
}
