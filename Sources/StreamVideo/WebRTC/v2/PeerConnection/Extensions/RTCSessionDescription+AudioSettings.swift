//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCSessionDescription: @unchecked Sendable {
    func withOpusDTX(_ isEnabled: Bool) -> RTCSessionDescription {
        guard isEnabled else { return self }
        let updatedSDP = sdp.replacingOccurrences(
            of: "useinbandfec=1",
            with: "useinbandfec=1;usedtx=1"
        )
        return .init(type: type, sdp: updatedSDP)
    }

    func withRedundantCoding(_ isEnabled: Bool) -> RTCSessionDescription {
        guard isEnabled else { return self }
        return .init(type: type, sdp: sdp.preferredRedCodec)
    }
}
