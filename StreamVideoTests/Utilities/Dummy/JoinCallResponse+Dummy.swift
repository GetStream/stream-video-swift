//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension JoinCallResponse {
    static func dummy(
        call: CallResponse = .dummy(),
        created: Bool = false,
        credentials: Credentials = .dummy(),
        duration: String = "",
        members: [MemberResponse] = [],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability] = [],
        playback: PlaybackResponse? = nil,
        statsOptions: StatsOptions = .init(enableRtcStats: false, reportingIntervalMs: 0)
    ) -> JoinCallResponse {
        .init(
            call: call,
            created: created,
            credentials: credentials,
            duration: duration,
            members: members,
            membership: membership,
            ownCapabilities: ownCapabilities,
            playback: playback,
            statsOptions: statsOptions
        )
    }

    /// A response the backend returns when it grants HLS playback: blank SFU
    /// credentials and a `playback` value.
    static func dummyHLSGrant(
        call: CallResponse = .dummy(),
        ownCapabilities: [OwnCapability] = [],
        playback: PlaybackResponse = .dummy()
    ) -> JoinCallResponse {
        .dummy(
            call: call,
            credentials: .dummy(
                server: .dummy(edgeName: "", url: "", wsEndpoint: ""),
                token: ""
            ),
            ownCapabilities: ownCapabilities,
            playback: playback
        )
    }
}
