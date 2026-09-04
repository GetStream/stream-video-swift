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
        noiseCancellation: NoiseCancellationSettingsRequest? = nil,
        opusDtxEnabled: Bool = false,
        redundantCodingEnabled: Bool = false,
        speakerDefaultOn: Bool = false
    ) -> AudioSettings {
        .init(
            accessRequestEnabled: accessRequestEnabled,
            defaultDevice: defaultDevice,
            hifiAudioEnabled: hifiAudioEnabled,
            micDefaultOn: micDefaultOn,
            noiseCancellation: noiseCancellation,
            opusDtxEnabled: opusDtxEnabled,
            redundantCodingEnabled: redundantCodingEnabled,
            speakerDefaultOn: speakerDefaultOn
        )
    }
}
