//
//  HomeViewModel.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 24.6.22.
//

import Foundation
import WebRTC

@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var signalingConnected = false
    @Published var localSDP = false
    @Published var localCandidates = 0
    @Published var remoteSDP = false
    @Published var remoteCandidates = 0
    @Published var webRTCStatus = ""
    
    var signallingStatus: String {
        signalingConnected ? "Connected" : "Not connected"
    }
    
    private let signalClient: SignalingClient
    private let webRTCClient: WebRTCClient
    
    init(signalClient: SignalingClient, webRTCClient: WebRTCClient) {
        self.signalClient = signalClient
        self.webRTCClient = webRTCClient
        self.webRTCClient.delegate = self
        self.signalClient.delegate = self
        self.signalClient.connect()
    }
    
    func sendOffer() {
        self.webRTCClient.offer { sdp in
            DispatchQueue.main.async {
                self.localSDP = true
                self.signalClient.send(sdp: sdp)
            }
        }
    }
    
    func sendAnswer() {
        self.webRTCClient.answer { sdp in
            DispatchQueue.main.async {
                self.localSDP = true
                self.signalClient.send(sdp: sdp)
            }
        }
    }
    
}

extension HomeViewModel: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        DispatchQueue.main.async {
            self.localCandidates += 1
            self.signalClient.send(candidate: candidate)
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        DispatchQueue.main.async {
            self.webRTCStatus = state.description.capitalized
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        print("did receive data")
    }
}

extension HomeViewModel: SignalClientDelegate {
    
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        DispatchQueue.main.async {
            self.signalingConnected = true
        }
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        DispatchQueue.main.async {
            self.signalingConnected = false
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        print("Received remote sdp")
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            DispatchQueue.main.async {
                self.remoteSDP = true
            }
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        self.webRTCClient.set(remoteCandidate: candidate) { error in
            print("Received remote candidate")
            DispatchQueue.main.async {
                self.remoteCandidates += 1
            }
        }
    }
    
}
