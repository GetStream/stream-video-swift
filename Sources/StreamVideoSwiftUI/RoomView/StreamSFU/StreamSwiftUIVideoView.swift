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
            VStack {
                ForEach(participants) { participant in
                    RTCMTLVideoViewSwiftUI(size: reader.size) { view in
                        if let track = participant.track, participant.id != streamVideo.userInfo.id {
                            log.debug("adding track to a view \(view)")
                            track.add(view)
                        }
                    }
                    .background(Color.red)
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
        view.videoContentMode = .scaleAspectFill
        handleRendering(view)
        return view
    }
    
    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        handleRendering(uiView)
    }
}
