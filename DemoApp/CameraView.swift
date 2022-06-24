//
//  CameraView.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 24.6.22.
//

import SwiftUI
import WebRTC

struct CameraView: UIViewRepresentable {

    var webRTCClient: WebRTCClient
    var frame: CGRect
    var isCurrentUser: Bool
    var cameraPosition: AVCaptureDevice.Position
    
    func makeUIView(context: Context) -> RTCMTLVideoView {
        let videoView = RTCMTLVideoView(frame: frame)
        videoView.videoContentMode = .scaleAspectFill
        if isCurrentUser {
            webRTCClient.startCaptureLocalVideo(renderer: videoView, cameraPosition: cameraPosition)
        } else {
            webRTCClient.renderRemoteVideo(to: videoView)
        }
        return videoView
    }
    
    func updateUIView(_ videoView: RTCMTLVideoView, context: Context) {
        if isCurrentUser {
            webRTCClient.startCaptureLocalVideo(renderer: videoView, cameraPosition: cameraPosition)
        }
    }
    
}
