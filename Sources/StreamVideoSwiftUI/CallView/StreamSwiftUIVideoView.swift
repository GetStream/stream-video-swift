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
    private var onLocalVideoUpdate: (StreamMTLVideoView) -> Void
    
    public init(
        callSettings: CallSettings,
        showBackground: Bool = true,
        onLocalVideoUpdate: @escaping (StreamMTLVideoView) -> Void
    ) {
        self.callSettings = callSettings
        self.showBackground = showBackground
        self.onLocalVideoUpdate = onLocalVideoUpdate
    }
            
    public var body: some View {
        GeometryReader { reader in
            ZStack {
                if callSettings.videoOn {
                    StreamVideoViewSwiftUI(id: streamVideo.userInfo.id, size: reader.size) { view in
                        onLocalVideoUpdate(view)
                    }
                    .rotation3DEffect(
                        .degrees(callSettings.cameraPosition == .front ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                } else if showBackground || streamVideo.userInfo.imageURL == nil {
                    CallParticipantImageView(
                        id: streamVideo.userInfo.id,
                        name: streamVideo.userInfo.name,
                        imageURL: streamVideo.userInfo.imageURL
                    )
                    .frame(maxWidth: reader.size.width)
                } else {
                    LazyImage(url: streamVideo.userInfo.imageURL)
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

struct StreamVideoViewSwiftUI: UIViewRepresentable {
        
    typealias UIViewType = StreamMTLVideoView
    
    var id: String
    var size: CGSize
    var handleRendering: (StreamMTLVideoView) -> Void

    func makeUIView(context: Context) -> StreamMTLVideoView {
        let view = StreamMTLVideoView(frame: .init(origin: .zero, size: size))
        view.videoContentMode = .scaleAspectFill
        view.backgroundColor = UIColor.black
        handleRendering(view)
        return view
    }
    
    func updateUIView(_ uiView: StreamMTLVideoView, context: Context) {
        handleRendering(uiView)
    }
}

public class StreamMTLVideoView: RTCMTLVideoView {
    
    weak var track: RTCVideoTrack?
    
    public func add(track: RTCVideoTrack) {
//        guard self.track == nil else { return }
        log.debug("Adding track to the view")
        self.track = track
        track.add(self)
    }
}
