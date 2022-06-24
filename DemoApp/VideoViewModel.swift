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
    
    init(webRTCClient: WebRTCClient) {
        self.webRTCClient = webRTCClient
    }
    
}
