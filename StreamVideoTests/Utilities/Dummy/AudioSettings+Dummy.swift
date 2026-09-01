//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension AudioSettings {
    static func dummy(
        accessRequestEnabled: Bool = false,
        defaultDevice: DefaultDevice = .speaker,
        hifiAudioEnabled: Bool? = nil,
        micDefaultOn: Bool = false,
        opusDtxEnabled: Bool = false,
        redundantCodingEnabled: Bool = false,
        speakerDefaultOn: Bool = false
    ) -> AudioSettings {
        .init(
            accessRequestEnabled: accessRequestEnabled,
            defaultDevice: defaultDevice,
            hifiAudioEnabled: hifiAudioEnabled,
            micDefaultOn: micDefaultOn,
            opusDtxEnabled: opusDtxEnabled,
            redundantCodingEnabled: redundantCodingEnabled,
            speakerDefaultOn: speakerDefaultOn
        )
    }
}
