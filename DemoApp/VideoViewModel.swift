//
//  VideoViewModel.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 24.6.22.
//

import Foundation
import WebRTC

@MainActor
class VideoViewModel: ObservableObject {
    
    let webRTCClient: WebRTCClient
    
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    
    init(webRTCClient: WebRTCClient) {
        self.webRTCClient = webRTCClient
    }
    
    func changeCameraPosition() {
        cameraPosition = cameraPosition == .front ? .back : .front
    }
    
}
