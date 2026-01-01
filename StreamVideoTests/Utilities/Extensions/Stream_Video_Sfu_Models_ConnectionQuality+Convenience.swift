//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

extension Stream_Video_Sfu_Models_ConnectionQuality {

    init(_ source: ConnectionQuality) {
        switch source {
        case .poor:
            self = .poor
        case .good:
            self = .good
        case .excellent:
            self = .excellent
        default:
            self = .unspecified
        }
    }
}
