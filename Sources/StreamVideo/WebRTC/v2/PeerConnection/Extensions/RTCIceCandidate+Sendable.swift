//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

/// Extends RTCIceCandidate to conform to the Sendable protocol.
///
/// - Note: The @unchecked attribute indicates that the conformance to Sendable
///         is not automatically checked by the compiler. Ensure thread safety
///         when using this type across concurrency domains.
extension RTCIceCandidate: @unchecked Sendable {}
