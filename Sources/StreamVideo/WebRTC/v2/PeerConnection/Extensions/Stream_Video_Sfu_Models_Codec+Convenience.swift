//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

extension Stream_Video_Sfu_Models_Codec {
    /// Initializes a Stream_Video_Sfu_Models_Codec from an RTCVideoCodecInfo.
    ///
    /// - Parameter source: The RTCVideoCodecInfo to convert.
    /// - Note: Only the 'name' property is currently copied from the source.
    init(_ source: RTCVideoCodecInfo) {
        self.init()
        name = source.name
    }
}
