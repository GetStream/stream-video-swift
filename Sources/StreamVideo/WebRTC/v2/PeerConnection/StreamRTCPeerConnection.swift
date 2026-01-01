//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Represents a WebRTC peer connection with additional Stream-specific functionality.
final class StreamRTCPeerConnection: StreamRTCPeerConnectionProtocol, @unchecked Sendable {

    /// A dictionary groups transceivers based on the type of their carrying track.
    @Atomic private var transceiversMap: [TrackType: [RTCRtpTransceiver]] = [:]

    /// The configuration used to initialize the peer connection.
    ///
    /// Contains settings such as ICE servers, SDP semantics, bundle policy,
    /// and other connection-related options.
    var configuration: RTCConfiguration { source.configuration }

    /// The remote session description of the peer connection.
    var remoteDescription: RTCSessionDescription? { source.remoteDescription }

    /// The list of RTP transceivers associated with this peer connection.
    var transceivers: [RTCRtpTransceiver] { source.transceivers }

    /// A subject for publishing peer connection events.
    var subject: PassthroughSubject<RTCPeerConnectionEvent, Never> { delegatePublisher.publisher }

    /// A dispatch queue for handling peer connection operations.
    let dispatchQueue = DispatchQueue(label: "io.getstream.peerconnection")

    private let disposableBag = DisposableBag()

    /// A publisher for RTCPeerConnectionEvents.
    lazy var publisher: AnyPublisher<RTCPeerConnectionEvent, Never> = delegatePublisher
        .publisher
        .receive(on: dispatchQueue)
        .eraseToAnyPublisher()

    var iceConnectionState: RTCIceConnectionState { source.iceConnectionState }

    var connectionState: RTCPeerConnectionState { source.connectionState }

    private let delegatePublisher = DelegatePublisher()
    private let source: RTCPeerConnection

    /// Initializes a new StreamRTCPeerConnection.
    ///
    /// - Parameters:
    ///   - factory: The peer connection factory.
    ///   - configuration: The configuration for the peer connection.
    ///   - constraints: The media constraints (default is `.defaultConstraints`).
    convenience init(
        _ factory: PeerConnectionFactory,
        configuration: RTCConfiguration,
        constraints: RTCMediaConstraints = .defaultConstraints
    ) throws {
        self.init(
            source: try factory.makePeerConnection(
                configuration: configuration,
                constraints: constraints,
                delegate: nil
            )
        )
    }

    private init(
        source: RTCPeerConnection
    ) {
        self.source = source
        source.delegate = delegatePublisher
    }

    // MARK: - Concurrency API

    /// Sets the local description asynchronously.
    ///
    /// - Parameter sessionDescription: The RTCSessionDescription to set as the local description.
    /// - Throws: An error if setting the local description fails.
    func setLocalDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(
                    throwing: ClientError.Unknown("RTCPeerConnection instance is unavailable.")
                )
                return
            }

            source.setLocalDescription(sessionDescription) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        } as ()
    }

    /// Sets the remote description asynchronously.
    ///
    /// - Parameter sessionDescription: The RTCSessionDescription to set as the remote description.
    /// - Throws: An error if setting the remote description fails.
    func setRemoteDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(
                    throwing: ClientError.Unknown("RTCPeerConnection instance is unavailable.")
                )
                return
            }

            source.setRemoteDescription(sessionDescription) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    self.subject.send(HasRemoteDescription(sessionDescription: sessionDescription))
                    continuation.resume(returning: ())
                }
            }
        } as ()
    }

    /// Creates an offer asynchronously.
    ///
    /// - Parameter constraints: The media constraints to use.
    /// - Returns: The created RTCSessionDescription.
    /// - Throws: An error if the offer creation fails.
    func offer(
        for constraints: RTCMediaConstraints
    ) async throws -> RTCSessionDescription {
        try await source.offer(for: constraints)
    }

    /// Creates an answer asynchronously.
    ///
    /// - Parameter constraints: The media constraints to use.
    /// - Returns: The created RTCSessionDescription.
    /// - Throws: An error if the answer creation fails.
    func answer(
        for constraints: RTCMediaConstraints
    ) async throws -> RTCSessionDescription {
        try await source.answer(for: constraints)
    }

    /// Retrieves the statistics of the peer connection.
    ///
    /// - Returns: An RTCStatisticsReport containing the connection statistics.
    /// - Throws: An error if retrieving statistics fails.
    func statistics() async throws -> RTCStatisticsReport? {
        await source.statistics()
    }

    // MARK: - Forwarding API

    /// Adds a transceiver to the peer connection.
    ///
    /// - Parameters:
    ///   - track: The media track to add.
    ///   - transceiverInit: The initialization parameters for the transceiver.
    /// - Returns: The created RTCRtpTransceiver, or nil if creation fails.
    func addTransceiver(
        trackType: TrackType,
        with track: RTCMediaStreamTrack,
        init transceiverInit: RTCRtpTransceiverInit
    ) -> RTCRtpTransceiver? {
        let result = source.addTransceiver(with: track, init: transceiverInit)
        storeTransceiver(result, trackType: trackType)
        return result
    }

    func transceivers(for trackType: TrackType) -> [RTCRtpTransceiver] {
        transceiversMap[trackType] ?? []
    }

    /// Adds an ICE candidate to the peer connection.
    ///
    /// - Parameter candidate: The ICE candidate to add.
    /// - Throws: An error if adding the candidate fails.
    func add(_ candidate: RTCIceCandidate) async throws {
        try await source.add(candidate)
    }

    // MARK: - Publishing API

    /// Creates a publisher for a specific type of RTCPeerConnectionEvent.
    ///
    /// - Parameter eventType: The type of event to publish.
    /// - Returns: An AnyPublisher that emits events of the specified type.
    func publisher<T: RTCPeerConnectionEvent>(
        eventType: T.Type
    ) -> AnyPublisher<T, Never> {
        publisher.compactMap { $0 as? T }.eraseToAnyPublisher()
    }

    // MARK: - Connection Lifecycle

    /// Restarts the ICE gathering process.
    func restartIce() {
        source.restartIce()
    }

    /// Closes the peer connection.
    func close() async {
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            /// It's very important to close any transceivers **before** we close the connection, to make
            /// sure that access to `RTCVideoTrack` properties, will be handled correctly. Otherwise
            /// if we try to access any property/method on a `RTCVideoTrack` instance whose
            /// peerConnection has closed, we will get blocked on the Main Thread.
            self?.source.transceivers.forEach { $0.stopInternal() }
            self?.source.close()
        }
    }

    // MARK: - Private

    private func storeTransceiver(
        _ transceiver: RTCRtpTransceiver?,
        trackType: TrackType
    ) {
        guard let transceiver else { return }
        if transceiversMap[trackType] == nil {
            transceiversMap[trackType] = []
        }

        transceiversMap[trackType]?.append(transceiver)
    }
}
