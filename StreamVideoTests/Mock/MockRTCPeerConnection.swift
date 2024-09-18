//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCPeerConnection: StreamRTCPeerConnectionProtocol, Mockable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockRTCPeerConnection, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case setLocalDescription
        case setRemoteDescription
        case offer
        case answer
        case statistics
        case addTransceiver
        case addCandidate
        case restartICE
        case close
    }

    enum MockFunctionInputKey: Payloadable {
        case setLocalDescription(sessionDescription: RTCSessionDescription)
        case setRemoteDescription(sessionDescription: RTCSessionDescription)
        case offer(constraints: RTCMediaConstraints)
        case answer(constraints: RTCMediaConstraints)
        case statistics
        case addTransceiver(track: RTCMediaStreamTrack, transceiverInit: RTCRtpTransceiverInit)
        case addCandidate(candidate: RTCIceCandidate)
        case restartICE
        case close

        var payload: Any {
            switch self {
            case let .setLocalDescription(sessionDescription):
                return sessionDescription
            case let .setRemoteDescription(sessionDescription):
                return sessionDescription
            case let .offer(constraints):
                return constraints
            case let .answer(constraints):
                return constraints
            case .statistics:
                return ()
            case let .addTransceiver(track, transceiverInit):
                return (track, transceiverInit)
            case let .addCandidate(candidate):
                return candidate
            case .restartICE:
                return ()
            case .close:
                return ()
            }
        }
    }

    // MARK: - Implementation

    var remoteDescription: RTCSessionDescription?
    var transceivers: [RTCRtpTransceiver] = []
    var subject: PassthroughSubject<any RTCPeerConnectionEvent, Never> = .init()
    var publisher: AnyPublisher<any RTCPeerConnectionEvent, Never> { subject.eraseToAnyPublisher() }

    init() {
        stub(for: .offer, with: RTCSessionDescription(type: .offer, sdp: .unique))
        stub(for: .answer, with: RTCSessionDescription(type: .answer, sdp: .unique))
    }

    func setLocalDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        stubbedFunctionInput[.setLocalDescription]?
            .append(.setLocalDescription(sessionDescription: sessionDescription))
    }

    func setRemoteDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        stubbedFunctionInput[.setRemoteDescription]?
            .append(.setRemoteDescription(sessionDescription: sessionDescription))
    }

    func offer(
        for constraints: RTCMediaConstraints
    ) async throws -> RTCSessionDescription {
        stubbedFunctionInput[.offer]?
            .append(.offer(constraints: constraints))
        return stubbedFunction[.offer] as! RTCSessionDescription
    }

    func answer(
        for constraints: RTCMediaConstraints
    ) async throws -> RTCSessionDescription {
        stubbedFunctionInput[.answer]?
            .append(.answer(constraints: constraints))
        return stubbedFunction[.answer] as! RTCSessionDescription
    }

    func statistics() async throws -> RTCStatisticsReport? {
        stubbedFunctionInput[.statistics]?
            .append(.statistics)
        return stubbedFunction[.statistics] as? RTCStatisticsReport
    }

    func addTransceiver(
        with track: RTCMediaStreamTrack,
        init transceiverInit: RTCRtpTransceiverInit
    ) -> RTCRtpTransceiver? {
        stubbedFunctionInput[.addTransceiver]?
            .append(.addTransceiver(track: track, transceiverInit: transceiverInit))
        return stubbedFunction[.addTransceiver] as? RTCRtpTransceiver
    }

    func add(_ candidate: RTCIceCandidate) async throws {
        stubbedFunctionInput[.addCandidate]?
            .append(.addCandidate(candidate: candidate))
    }

    func publisher<T>(
        eventType: T.Type
    ) -> AnyPublisher<T, Never> where T: RTCPeerConnectionEvent {
        publisher.compactMap { $0 as? T }.eraseToAnyPublisher()
    }

    func restartIce() { stubbedFunctionInput[.restartICE]?.append(.restartICE) }

    func close() { stubbedFunctionInput[.close]?.append(.close) }
}
