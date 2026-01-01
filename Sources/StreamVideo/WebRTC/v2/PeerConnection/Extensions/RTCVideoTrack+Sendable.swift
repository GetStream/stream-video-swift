//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

/// Extends `RTCVideoTrack` to conform to the `Sendable` protocol.
///
/// This extension uses the `@unchecked` attribute to indicate that the conformance
/// to `Sendable` is not automatically checked by the compiler. The developer takes
/// responsibility for ensuring thread safety when using this type across concurrency domains.
extension RTCVideoTrack: @unchecked Sendable {}
