//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension ParticipantsStats {
    static func dummy(
        report: [String: [BaseStats]] = [:]
    ) -> ParticipantsStats {
        ParticipantsStats(report: report)
    }
}
