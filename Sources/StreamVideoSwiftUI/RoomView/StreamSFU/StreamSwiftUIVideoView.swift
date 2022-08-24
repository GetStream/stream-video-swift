//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

public struct LocalVideoView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    public init() {}
            
    public var body: some View {
        GeometryReader { reader in
            RTCMTLVideoViewSwiftUI(size: reader.size) { view in
                streamVideo.renderLocalVideo(renderer: view)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct RemoteParticipantsView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    private var participants: [CallParticipant]
    
    public init(participants: [CallParticipant]) {
        self.participants = participants
    }
    
    public var body: some View {
        GeometryReader { reader in
            // TODO: temp logic for testing.
            RTCMTLVideoViewSwiftUI(size: reader.size) { view in
                for participant in participants {
                    if let track = participant.track as? RTCVideoTrack, participant.id != streamVideo.userInfo.id {
                        track.add(view)
                        break
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RTCMTLVideoViewSwiftUI: UIViewRepresentable {
    
    typealias UIViewType = RTCMTLVideoView
    
    var size: CGSize
    var handleRendering: (RTCMTLVideoView) -> Void

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let view = RTCMTLVideoView(frame: .init(origin: .zero, size: size))
        handleRendering(view)
        return view
    }
    
    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {}
}
