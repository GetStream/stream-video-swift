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

    var signalingState: RTCSignalingState { source.signalingState }

    /// The list of RTP transceivers associated with this peer connection.
    var transceivers: [RTCRtpTransceiver] { source.transceivers }

    /// A subject for publishing peer connection events.
    var subject: PassthroughSubject<RTCPeerConnectionEvent, Never> { delegatePublisher.publisher }

    /// A dispatch queue for handling peer connection operations.
    let dispatchQueue = DispatchQueue(label: "io.getstream.peerconnection")

    /// Serial queue for the async SDP, ICE candidate and statistics APIs,
    /// plus native teardown.
    ///
    /// The Objective-C peer connection methods are synchronous proxies: the
    /// calling thread blocks until the signaling thread runs the call, even
    /// for methods that report their result through a completion handler.
    /// When the signaling thread stalls, for example behind a worker thread
    /// that waits on a decoder, every caller stalls with it. From Swift
    /// concurrency, each blocked call parks a thread of the cooperative
    /// pool, which has about one thread per CPU core, and a few of them are
    /// enough to starve unrelated async work across the SDK. From the main
    /// thread, the UI freezes. This queue keeps the wait on one thread per
    /// peer connection.
    ///
    /// Being serial, it hands calls to WebRTC in queue submission order.
    /// Completion callbacks can arrive later; this queue serializes API
    /// entry, not the entire asynchronous negotiation. ``close()`` runs
    /// after earlier queue entries, which skip WebRTC if already closed.
    private let operationQueue = DispatchQueue(label: "io.getstream.peerconnection.operations")

    /// Set as soon as ``close()`` is called, before the close itself runs.
    ///
    /// ``perform(_:)`` checks it before each queued call, so calls that were
    /// waiting on ``operationQueue`` fail with `CancellationError` without
    /// reaching WebRTC. Without it they would still wait for the signaling
    /// thread, only to be rejected there because the connection is closed.
    /// It is `@Atomic` because ``close()`` writes it on the caller's thread
    /// while ``operationQueue`` reads it.
    @Atomic private var isClosed = false

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
        try await perform { source, completion in
            source.setLocalDescription(sessionDescription) { completion(Self.result($0)) }
        }
    }

    /// Sets the remote description asynchronously.
    ///
    /// - Parameter sessionDescription: The RTCSessionDescription to set as the remote description.
    /// - Throws: An error if setting the remote description fails.
    func setRemoteDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        try await perform { source, completion in
            source.setRemoteDescription(sessionDescription) {
                completion(Self.result($0))
            }
        }

        // Native success may arrive after close. Serialize acceptance with the
        // close flag so teardown cannot occur between the check and publication.
        var wasClosed = false
        _isClosed.mutate { (isClosed: inout Bool) in
            wasClosed = isClosed
            if !isClosed, sessionDescription.type != .rollback {
                subject.send(HasRemoteDescription(sessionDescription: sessionDescription))
            }
        }
        guard !wasClosed else { throw CancellationError() }
    }

    /// Creates an offer asynchronously.
    ///
    /// - Parameter constraints: The media constraints to use.
    /// - Returns: The created RTCSessionDescription.
    /// - Throws: An error if the offer creation fails.
    func offer(
        for constraints: RTCMediaConstraints
    ) async throws -> RTCSessionDescription {
        // `RTCMediaConstraints` isn't marked `Sendable`, but it can't change
        // after it's created, so handing it to the operation queue is safe.
        nonisolated(unsafe) let constraints = constraints
        return try await perform { source, completion in
            source.offer(for: constraints) { completion(Self.result($0, $1)) }
        }
    }

    /// Creates an answer asynchronously.
    ///
    /// - Parameter constraints: The media constraints to use.
    /// - Returns: The created RTCSessionDescription.
    /// - Throws: An error if the answer creation fails.
    func answer(
        for constraints: RTCMediaConstraints
    ) async throws -> RTCSessionDescription {
        // See `offer(for:)`.
        nonisolated(unsafe) let constraints = constraints
        return try await perform { source, completion in
            source.answer(for: constraints) { completion(Self.result($0, $1)) }
        }
    }

    /// Retrieves the statistics of the peer connection.
    ///
    /// - Returns: An RTCStatisticsReport containing the connection statistics.
    /// - Throws: An error if retrieving statistics fails.
    func statistics() async throws -> RTCStatisticsReport? {
        try await perform { source, completion in
            source.statistics { completion(.success($0)) }
        }
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
        try await perform { source, completion in
            source.add(candidate) { completion(Self.result($0)) }
        }
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
    ///
    /// The closed flag is set right away, so calls still waiting on
    /// ``operationQueue`` fail with `CancellationError` without reaching
    /// WebRTC. The coordinator's negotiation handlers already ignore that
    /// error, which matches how the JS SDK drops work that fails after
    /// `dispose()`.
    ///
    /// The close itself is queued behind the call WebRTC may be running, and
    /// this method returns without waiting for it. WebRTC runs its calls one
    /// at a time on the signaling thread, so a close can't overtake a
    /// running call whichever thread sends it. Waiting here would let a
    /// stalled WebRTC block `WebRTCStateAdapter.cleanUp()`, which closes the
    /// peer connections before it disconnects from the SFU.
    ///
    /// This used to run on the main actor. WebRTC doesn't require that:
    /// `stopInternal()` and `close()` are both proxied to the signaling
    /// thread from any caller. On the main thread, a stalled signaling
    /// thread froze the UI while the user left the call.
    ///
    /// Calling it again is a no-op.
    func close() async {
        // Read and set in one locked step, so concurrent calls close once.
        var wasClosed = false
        _isClosed.mutate { (value: inout Bool) in
            wasClosed = value
            value = true
        }
        guard !wasClosed else { return }

        operationQueue.async { [self] in
            // Stop the transceivers before closing the connection. Otherwise
            // reading a property of an `RTCVideoTrack` whose peer connection
            // has closed can block the reading thread, and renderers may
            // still be reading their tracks at this point.
            source.transceivers.forEach { $0.stopInternal() }
            source.close()
        }
    }

    // MARK: - Private

    /// Runs a WebRTC call on ``operationQueue`` and awaits its completion
    /// handler.
    ///
    /// The calling task suspends without holding a thread, so a stalled
    /// signaling thread blocks only ``operationQueue``. The closed check
    /// runs when the call reaches the front of the queue. Checking when the
    /// call is queued would miss a close that arrives while it waits.
    ///
    /// - Note: If WebRTC never calls the completion handler, the caller stays
    ///   suspended. This matches the previous continuation-based calls.
    private func perform<T: Sendable>(
        _ operation: @escaping @Sendable (
            RTCPeerConnection,
            @escaping @Sendable (Result<T, Error>) -> Void
        ) -> Void
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            operationQueue.async { [self] in
                guard !isClosed else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                operation(source) { continuation.resume(with: $0) }
            }
        }
    }

    /// Maps a WebRTC completion that reports only an optional error.
    private static func result(_ error: Error?) -> Result<Void, Error> {
        error.map { .failure($0) } ?? .success(())
    }

    /// Maps a WebRTC completion that reports a description or an error.
    ///
    /// WebRTC should always provide one of the two. The fallback error
    /// covers the case where it provides neither, so the continuation still
    /// resumes instead of leaking.
    private static func result(
        _ sessionDescription: RTCSessionDescription?,
        _ error: Error?
    ) -> Result<RTCSessionDescription, Error> {
        if let sessionDescription {
            return .success(sessionDescription)
        }
        return .failure(error ?? ClientError.Unknown("WebRTC returned no session description."))
    }

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
