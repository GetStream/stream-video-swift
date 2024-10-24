//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCSessionDescription: @unchecked Sendable {
    /// Enables or disables Opus DTX in the session description.
    ///
    /// - Parameter isEnabled: Whether to enable Opus DTX.
    /// - Returns: A new RTCSessionDescription with Opus DTX enabled or disabled.
    func withOpusDTX(_ isEnabled: Bool) -> RTCSessionDescription {
        guard isEnabled else { return self }
        let updatedSDP = sdp.replacingOccurrences(
            of: "useinbandfec=1",
            with: "useinbandfec=1;usedtx=1"
        )
        return .init(type: type, sdp: updatedSDP)
    }

    /// Enables or disables redundant coding in the session description.
    ///
    /// - Parameter isEnabled: Whether to enable redundant coding.
    /// - Returns: A new RTCSessionDescription with redundant coding enabled or
    ///            disabled.
    func withRedundantCoding(_ isEnabled: Bool) -> RTCSessionDescription {
        guard isEnabled else { return self }
        return .init(type: type, sdp: sdp.preferredRedCodec)
    }
}
