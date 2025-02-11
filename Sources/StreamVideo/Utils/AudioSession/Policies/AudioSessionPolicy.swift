//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol AudioSessionPolicy: Sendable {

    func configuration(
        for callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) -> AudioSessionConfiguration
}
