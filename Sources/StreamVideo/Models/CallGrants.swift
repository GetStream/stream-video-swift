//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes the publishing rights the SFU currently grants to the local
/// participant.
///
/// Grants arrive with the `callGrantsUpdated` SFU event and take precedence
/// over the capabilities the coordinator reported for the call. They only
/// describe audio, video and screensharing; every other capability is left
/// untouched.
struct CallGrants: Hashable, Sendable {

    /// Whether the local participant is allowed to publish audio.
    var canPublishAudio: Bool

    /// Whether the local participant is allowed to publish video.
    var canPublishVideo: Bool

    /// Whether the local participant is allowed to share their screen.
    var canScreenshare: Bool

    /// Initializes grants with the provided values.
    ///
    /// - Parameters:
    ///   - canPublishAudio: Whether publishing audio is allowed.
    ///   - canPublishVideo: Whether publishing video is allowed.
    ///   - canScreenshare: Whether screensharing is allowed.
    init(
        canPublishAudio: Bool,
        canPublishVideo: Bool,
        canScreenshare: Bool
    ) {
        self.canPublishAudio = canPublishAudio
        self.canPublishVideo = canPublishVideo
        self.canScreenshare = canScreenshare
    }

    /// Initializes grants from the backend protobuf payload.
    ///
    /// - Parameter source: The raw protobuf grants value.
    init(_ source: Stream_Video_Sfu_Models_CallGrants) {
        self.init(
            canPublishAudio: source.canPublishAudio,
            canPublishVideo: source.canPublishVideo,
            canScreenshare: source.canScreenshare
        )
    }

    /// Applies the grants on top of the provided capabilities.
    ///
    /// A granted capability is added when it's missing and a revoked one is
    /// removed when it's present, so the result always reflects the grants
    /// regardless of the order in which updates arrive. Applying the same
    /// grants twice produces the same result.
    ///
    /// - Parameter capabilities: The capabilities to apply the grants on.
    /// - Returns: The capabilities updated with the current grants.
    func applied(to capabilities: [OwnCapability]) -> [OwnCapability] {
        var result = capabilities

        for (capability, isAllowed) in [
            (OwnCapability.sendAudio, canPublishAudio),
            (OwnCapability.sendVideo, canPublishVideo),
            (OwnCapability.screenshare, canScreenshare)
        ] {
            let index = result.firstIndex(of: capability)

            if isAllowed, index == nil {
                result.append(capability)
            } else if !isAllowed, let index {
                result.remove(at: index)
            }
        }

        return result
    }
}
