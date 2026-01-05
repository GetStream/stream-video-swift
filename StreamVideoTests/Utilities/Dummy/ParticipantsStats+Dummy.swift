//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
