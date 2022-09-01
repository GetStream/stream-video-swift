//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI
import WebRTC

public struct LocalVideoView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    private let callSettings: CallSettings
    private var showBackground: Bool
    private var onLocalVideoUpdate: (RTCMTLVideoView) -> Void
    
    public init(
        callSettings: CallSettings,
        showBackground: Bool = true,
        onLocalVideoUpdate: @escaping (RTCMTLVideoView) -> Void
    ) {
        self.callSettings = callSettings
        self.showBackground = showBackground
        self.onLocalVideoUpdate = onLocalVideoUpdate
    }
            
    public var body: some View {
        GeometryReader { reader in
            ZStack {
                if callSettings.videoOn {
                    RTCMTLVideoViewSwiftUI(size: reader.size) { view in
                        onLocalVideoUpdate(view)
                    }
                } else if showBackground || streamVideo.userInfo.imageURL == nil {
                    CallParticipantImageView(
                        id: streamVideo.userInfo.id,
                        name: streamVideo.userInfo.name ?? streamVideo.userInfo.id,
                        imageURL: streamVideo.userInfo.imageURL
                    )
                    .frame(maxWidth: reader.size.width)
                } else {
                    LazyImage(source: streamVideo.userInfo.imageURL)
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: reader.size.width)
                }
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
