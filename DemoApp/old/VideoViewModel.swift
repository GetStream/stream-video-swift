//
//  VideoViewModel.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 24.6.22.
//

import Foundation
import WebRTC

class VideoViewModel: ObservableObject {
    
    let webRTCClient: WebRTCClient
    let signalClient: SignalingClient
    
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    
    @Published private(set) var videoShown = true
    @Published private(set) var muteOn = false
    
    init(webRTCClient: WebRTCClient, signalClient: SignalingClient) {
        self.webRTCClient = webRTCClient
        self.signalClient = signalClient
    }
    
    func changeCameraPosition() {
        cameraPosition = cameraPosition == .front ? .back : .front
    }
    
    func changeVideoState() {
        videoShown.toggle()
        if videoShown {
            webRTCClient.showVideo()
        } else {
            webRTCClient.hideVideo()
        }
    }
    
    func stopCall(completion: @escaping () -> ()) {
        webRTCClient.closeConnection()
        completion()
    }
    
    func changeMuteState() {
        muteOn.toggle()
        if muteOn {
            self.webRTCClient.muteAudio()
        } else {
            self.webRTCClient.unmuteAudio()
        }
    }
    
}
