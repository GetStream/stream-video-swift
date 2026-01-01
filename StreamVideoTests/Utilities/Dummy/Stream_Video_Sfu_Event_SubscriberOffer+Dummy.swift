//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

extension Stream_Video_Sfu_Event_SubscriberOffer {
    static func dummy(
        iceRestart: Bool = false,
        sdp: String = .unique
    ) -> Stream_Video_Sfu_Event_SubscriberOffer {
        var result = Stream_Video_Sfu_Event_SubscriberOffer()
        result.iceRestart = iceRestart
        result.sdp = sdp
        return result
    }
}
