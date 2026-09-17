//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Stream_Video_Sfu_Models_CallGrants {

    /// Applies the publishing rights described by the grants on the provided
    /// capabilities.
    ///
    /// Grants only describe audio, video and screensharing, so every other
    /// capability is left untouched. A granted capability is inserted and a
    /// revoked one is removed, which makes applying the same grants twice
    /// produce the same result.
    ///
    /// - Parameter capabilities: The capabilities to apply the grants on.
    /// - Returns: The capabilities updated with the grants.
    func applied(to capabilities: Set<OwnCapability>) -> Set<OwnCapability> {
        var result = capabilities

        for (capability, isAllowed) in [
            (OwnCapability.sendAudio, canPublishAudio),
            (OwnCapability.sendVideo, canPublishVideo),
            (OwnCapability.screenshare, canScreenshare)
        ] {
            if isAllowed {
                result.insert(capability)
            } else {
                result.remove(capability)
            }
        }

        return result
    }
}
