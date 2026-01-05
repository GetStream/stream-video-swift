//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallSettingsResponse {

    /// Determines if the speaker should be enabled based on a priority hierarchy of
    /// settings.
    ///
    /// The priority order is as follows:
    /// 1. If video camera is set to be on by default, speaker is enabled
    /// 2. If audio speaker is set to be on by default, speaker is enabled
    /// 3. If the default audio device is set to speaker, speaker is enabled
    ///
    /// This ensures that the speaker state aligns with the most important user
    /// preference or system requirement.
    var speakerOnWithSettingsPriority: Bool {
        if video.cameraDefaultOn {
            return true
        } else if audio.speakerDefaultOn {
            return true
        } else {
            return audio.defaultDevice == .speaker
        }
    }
}
