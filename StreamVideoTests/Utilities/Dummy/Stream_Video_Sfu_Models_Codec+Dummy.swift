//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension Stream_Video_Sfu_Models_Codec {
    static func dummy(
        mimeType: String = String(),
        scalabilityMode: String = String(),
        fmtp: String = String()
    ) -> Stream_Video_Sfu_Models_Codec {
        var result = Stream_Video_Sfu_Models_Codec()
        result.mimeType = mimeType
        result.scalabilityMode = scalabilityMode
        result.fmtp = fmtp
        return result
    }
}
