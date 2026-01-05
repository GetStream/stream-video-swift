//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension VideoSettings {
    static func dummy(
        accessRequestEnabled: Bool = false,
        cameraDefaultOn: Bool = false,
        cameraFacing: CameraFacing = .front,
        enabled: Bool = false,
        targetResolution: TargetResolution = .dummy()
    ) -> VideoSettings {
        .init(
            accessRequestEnabled: accessRequestEnabled,
            cameraDefaultOn: cameraDefaultOn,
            cameraFacing: cameraFacing,
            enabled: enabled,
            targetResolution: targetResolution
        )
    }
}
