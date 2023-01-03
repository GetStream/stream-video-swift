//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI
import WebRTC

public struct LocalVideoView: View {

    @Injected(\.streamVideo) var streamVideo

    private let callSettings: CallSettings
    private var showBackground: Bool
    private var onLocalVideoUpdate: (VideoRenderer) -> Void

    public init(
        callSettings: CallSettings,
        showBackground: Bool = true,
        onLocalVideoUpdate: @escaping (VideoRenderer) -> Void
    ) {
        self.callSettings = callSettings
        self.showBackground = showBackground
        self.onLocalVideoUpdate = onLocalVideoUpdate
    }

    public var body: some View {
        GeometryReader { reader in
            VideoRendererView(id: streamVideo.user.id, size: reader.size) { view in
                onLocalVideoUpdate(view)
            }
            .rotation3DEffect(
                .degrees(callSettings.cameraPosition == .front ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(showVideo ? 1 : 0)
            .overlay(
                CallParticipantImageView(
                    id: streamVideo.user.id,
                    name: streamVideo.user.name,
                    imageURL: streamVideo.user.imageURL
                )
                .frame(maxWidth: reader.size.width)
                .opacity(showVideo ? 0 : 1)
            )
            .edgesIgnoringSafeArea(.all)
            .background(Color(UIColor.systemBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var showVideo: Bool {
        callSettings.videoOn && streamVideo.videoConfig.videoEnabled
    }
}

public struct VideoRendererView: UIViewRepresentable {

    public typealias UIViewType = VideoRenderer

    var id: String
    var size: CGSize
    var contentMode: UIView.ContentMode
    var handleRendering: (VideoRenderer) -> Void

    public init(
        id: String,
        size: CGSize,
        contentMode: UIView.ContentMode = .scaleAspectFill,
        handleRendering: @escaping (VideoRenderer) -> Void
    ) {
        self.id = id
        self.size = size
        self.handleRendering = handleRendering
        self.contentMode = contentMode
    }

    public func makeUIView(context: Context) -> VideoRenderer {
        let view = VideoRenderer(frame: .init(origin: .zero, size: size))
        view.videoContentMode = contentMode
        view.backgroundColor = UIColor.black
        handleRendering(view)
        return view
    }

    public func updateUIView(_ uiView: VideoRenderer, context: Context) {
        handleRendering(uiView)
    }
}

public class VideoRenderer: RTCMTLVideoView {

    let queue = DispatchQueue(label: "video-track")

    weak var track: RTCVideoTrack?

    public func add(track: RTCVideoTrack) {
        queue.sync {
            guard track.trackId != self.track?.trackId else { return }
            self.track?.remove(self)
            log.debug("Adding track to the view")
            self.track = track
            track.add(self)
        }
    }

    deinit {
        log.debug("Deinit of video view")
        track?.remove(self)
    }
}
