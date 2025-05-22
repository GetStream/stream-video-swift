//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCPeerConnection: StreamRTCPeerConnectionProtocol, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockRTCPeerConnection, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub(for function: FunctionKey, with value: some Any) { stubbedFunction[function] = value }

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
        case transceivers
    }

    enum MockFunctionInputKey: Payloadable {
        case setLocalDescription(sessionDescription: RTCSessionDescription)
        case setRemoteDescription(sessionDescription: RTCSessionDescription)
        case offer(constraints: RTCMediaConstraints)
        case answer(constraints: RTCMediaConstraints)
        case statistics
        case addTransceiver(trackType: TrackType, track: RTCMediaStreamTrack, transceiverInit: RTCRtpTransceiverInit)
        case addCandidate(candidate: RTCIceCandidate)
        case restartICE
        case close
        case transceivers(trackType: TrackType)

        var payload: Any {
            switch self {
            case let .setLocalDescription(sessionDescription):
                sessionDescription
            case let .setRemoteDescription(sessionDescription):
                sessionDescription
            case let .offer(constraints):
                constraints
            case let .answer(constraints):
                constraints
            case .statistics:
                ()
            case let .addTransceiver(trackType, track, transceiverInit):
                (trackType, track, transceiverInit)
            case let .addCandidate(candidate):
                candidate
            case .restartICE:
                ()
            case .close:
                ()
            case let .transceivers(trackType):
                trackType
            }
        }
    }

    // MARK: - Implementation

    var remoteDescription: RTCSessionDescription? {
        get { self[dynamicMember: \.remoteDescription] }
        set { _ = newValue }
    }

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
        if let result = stubbedFunction[.offer] as? RTCSessionDescription {
            return result
        } else if let result = stubbedFunction[.offer] as? StubVariantResultProvider<RTCSessionDescription> {
            return result.getResult(for: timesCalled(.offer))
        } else {
            return RTCSessionDescription(type: .offer, sdp: .unique)
        }
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
        trackType: TrackType,
        with track: RTCMediaStreamTrack,
        init transceiverInit: RTCRtpTransceiverInit
    ) -> RTCRtpTransceiver? {
        stubbedFunctionInput[.addTransceiver]?
            .append(.addTransceiver(trackType: trackType, track: track, transceiverInit: transceiverInit))
        if let result = stubbedFunction[.addTransceiver] as? RTCRtpTransceiver {
            result.sender.track = track
            return result
        } else if
            let provider = stubbedFunction[.addTransceiver] as? StubVariantResultProvider<RTCRtpTransceiver> {
            let result = provider.getResult(for: timesCalled(.addTransceiver))
            result.sender.track = track
            return result
        } else {
            return nil
        }
    }

    func transceivers(
        for trackType: TrackType
    ) -> [RTCRtpTransceiver] {
        stubbedFunctionInput[.transceivers]?
            .append(.transceivers(trackType: trackType))
        return stubbedFunction[.transceivers] as? [RTCRtpTransceiver] ?? []
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
