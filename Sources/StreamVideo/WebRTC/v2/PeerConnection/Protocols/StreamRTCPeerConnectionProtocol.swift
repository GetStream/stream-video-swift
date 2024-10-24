//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import StreamWebRTC

/// Protocol defining the interface for a WebRTC peer connection with Stream-specific functionality.
protocol StreamRTCPeerConnectionProtocol: AnyObject {
    /// The remote session description of the peer connection.
    var remoteDescription: RTCSessionDescription? { get }

    /// The list of RTP transceivers associated with this peer connection.
    var transceivers: [RTCRtpTransceiver] { get }

    /// A subject for publishing peer connection events.
    var subject: PassthroughSubject<RTCPeerConnectionEvent, Never> { get }

    /// A publisher for RTCPeerConnectionEvents.
    var publisher: AnyPublisher<RTCPeerConnectionEvent, Never> { get }

    /// Sets the local description asynchronously.
    /// - Parameter sessionDescription: The RTCSessionDescription to set as the local description.
    /// - Throws: An error if setting the local description fails.
    func setLocalDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws

    /// Sets the remote description asynchronously.
    /// - Parameter sessionDescription: The RTCSessionDescription to set as the remote description.
    /// - Throws: An error if setting the remote description fails.
    func setRemoteDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws

    /// Creates an offer asynchronously.
    /// - Parameter constraints: The media constraints to use.
    /// - Returns: The created RTCSessionDescription.
    /// - Throws: An error if the offer creation fails.
    func offer(
        for constraints: RTCMediaConstraints
    ) async throws -> RTCSessionDescription

    /// Creates an answer asynchronously.
    /// - Parameter constraints: The media constraints to use.
    /// - Returns: The created RTCSessionDescription.
    /// - Throws: An error if the answer creation fails.
    func answer(
        for constraints: RTCMediaConstraints
    ) async throws -> RTCSessionDescription

    /// Retrieves the statistics of the peer connection.
    /// - Returns: An RTCStatisticsReport containing the connection statistics.
    /// - Throws: An error if retrieving statistics fails.
    func statistics() async throws -> RTCStatisticsReport?

    /// Adds a transceiver to the peer connection.
    /// - Parameters:
    ///   - track: The media track to add.
    ///   - transceiverInit: The initialization parameters for the transceiver.
    /// - Returns: The created RTCRtpTransceiver, or nil if creation fails.
    func addTransceiver(
        with track: RTCMediaStreamTrack,
        init transceiverInit: RTCRtpTransceiverInit
    ) -> RTCRtpTransceiver?

    /// Adds an ICE candidate to the peer connection.
    /// - Parameter candidate: The ICE candidate to add.
    /// - Throws: An error if adding the candidate fails.
    func add(_ candidate: RTCIceCandidate) async throws

    /// Creates a publisher for a specific type of RTCPeerConnectionEvent.
    /// - Parameter eventType: The type of event to publish.
    /// - Returns: An AnyPublisher that emits events of the specified type.
    func publisher<T: RTCPeerConnectionEvent>(
        eventType: T.Type
    ) -> AnyPublisher<T, Never>

    /// Restarts the ICE gathering process.
    func restartIce()

    /// Closes the peer connection.
    func close() async
}
