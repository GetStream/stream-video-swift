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

    /// A publisher for RTCPeerConnectionEvents.
    lazy var publisher: AnyPublisher<RTCPeerConnectionEvent, Never> = delegatePublisher
        .publisher
        .receive(on: dispatchQueue)
        .eraseToAnyPublisher()

    var iceConnectionState: RTCIceConnectionState { source.iceConnectionState }

    var connectionState: RTCPeerConnectionState { source.connectionState }

    private let delegatePublisher = DelegatePublisher()
    private let source: RTCPeerConnection
    // Orders close claims with add checks and map insertion. Native calls
    // and awaited teardown must run outside this lock.
    private let lifecycleQueue = UnfairQueue()
    private var isClosed = false

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

    /// Adds a transceiver while the peer connection is open.
    ///
    /// The native add runs outside the lifecycle lock. If closure wins
    /// before the result is stored, this stops the new transceiver and
    /// returns `nil`. A result stored first is stopped by `close()`.
    ///
    /// - Parameters:
    ///   - track: The media track to add.
    ///   - transceiverInit: The initialization parameters for the transceiver.
    /// - Returns: The created transceiver, or `nil` if creation fails or
    ///   closure begins before it can be stored.
    func addTransceiver(
        trackType: TrackType,
        with track: RTCMediaStreamTrack,
        init transceiverInit: RTCRtpTransceiverInit
    ) -> RTCRtpTransceiver? {
        guard lifecycleQueue.sync({ isClosed }) == false else {
            // PeerConnection is closing. Do not add new transceivers.
            return nil
        }

        // libwebrtc does not reject an add after close, so check again once
        // the native add returns. The native call stays outside the lock.
        guard let result = source.addTransceiver(
            with: track,
            init: transceiverInit
        ) else {
            return nil
        }

        let isClosedAfterAdd: Bool = lifecycleQueue.sync {
            guard !isClosed else { return true }
            storeTransceiver(result, trackType: trackType)
            return false
        }
        guard !isClosedAfterAdd else {
            result.stopInternal()
            return nil
        }
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

    /// Stops transceivers and closes the peer connection on the main actor.
    ///
    /// The first caller awaits native teardown. A concurrent caller that
    /// finds closure already claimed returns before teardown finishes.
    /// An in-flight native add may stop its result after this returns.
    func close() async {
        let shouldClose: Bool = lifecycleQueue.sync {
            guard !isClosed else { return false }
            isClosed = true
            return true
        }
        guard shouldClose else { return }

        let source = self.source
        await MainActor.run {
            // Stop before close: later track-property access can block the
            // main thread if its peer connection is already closed.
            source.transceivers.forEach { $0.stopInternal() }
            source.close()
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
