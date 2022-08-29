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
            .edgesIgnoringSafeArea(.all)
            .background(Color(UIColor.systemBackground))
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
