//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf
import WebRTC

class DataChannel: NSObject, RTCDataChannelDelegate {
    
    private let dataChannel: RTCDataChannel
    private let eventDecoder: WebRTCEventDecoder
    
    var onStateChange: ((RTCDataChannelState) -> Void)?
    var onEventReceived: ((Event) -> Void)?
    
    init(dataChannel: RTCDataChannel, eventDecoder: WebRTCEventDecoder) {
        self.dataChannel = dataChannel
        self.eventDecoder = eventDecoder
        super.init()
        self.dataChannel.delegate = self
    }
    
    func send(data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: false)
        dataChannel.sendData(buffer)
    }
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        log.debug("Data channel state updated with \(dataChannel.readyState)")
        onStateChange?(dataChannel.readyState)
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if let event = try? eventDecoder.decode(from: buffer.data) {
            onEventReceived?(event)
        }
    }
}

extension Data {
    
    static var sample: Data {
        "ss".data(using: .utf8) ?? Data()
    }
}
