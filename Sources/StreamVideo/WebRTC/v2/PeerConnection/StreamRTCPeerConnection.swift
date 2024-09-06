//
//  StreamRTCPeerConnection.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 6/9/24.
//

import StreamWebRTC
import Foundation
import Combine

final class StreamRTCPeerConnection: RTCPeerConnection, @unchecked Sendable {

    private let delegatePublisher = DelegatePublisher()

    let dispatchQueue = DispatchQueue(label: "io.getstream.peerconnection")

    var subject: PassthroughSubject<RTCPeerConnectionEvent, Never> {
        delegatePublisher.publisher
    }

    lazy var publisher: AnyPublisher<RTCPeerConnectionEvent, Never> = delegatePublisher
        .publisher
        .receive(on: dispatchQueue)
        .eraseToAnyPublisher()

    func publisher<T: RTCPeerConnectionEvent>(
        eventType: T.Type
    ) -> AnyPublisher<T, Never> {
        publisher.compactMap { $0 as? T }.eraseToAnyPublisher()
    }
}
