//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import GoogleSignIn
import StreamVideo
import StreamVideoSwiftUI
import StreamWebRTC
import SwiftUI

@main
struct DemoApp: App {
    @State var streamVideo: StreamVideo?
    
    init() {
        // mmhfdzb5evj2
        streamVideo = StreamVideo(apiKey: "par8f5s3gn2j", user: .anonymous, token: UserToken(rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiIWFub24iLCJpc3MiOiJodHRwczovL3Byb250by5nZXRzdHJlYW0uaW8iLCJzdWIiOiJ1c2VyLyFhbm9uIiwiaWF0IjoxNzE1ODY4OTIwLCJjYWxsX2NpZHMiOlsibGl2ZXN0cmVhbTpsaXZlc3RyZWFtX2MzYWYxMDhiLTkyNDgtNDc3OC05OTdkLWI3OTkzMDM4Mjg4MSJdLCJleHAiOjE3MTY0NzM3MjV9.dkck9Vcs2go3fN2n4qklNDEwbqFgHa4BtzqYtDSVRq4"))
    }
    
    var body: some Scene {
        WindowGroup {
            LivestreamView()
        }
    }
}

struct LivestreamView: View {
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink {
                  LivestreamPlayer(type: "livestream", id: "livestream_c3af108b-9248-4778-997d-b79930382881")
//                    LivestreamPlayer(type: "livestream", id: "marceloooo")
                } label: {
                  Text("Join stream")
                }
            }
        }
    }
}
