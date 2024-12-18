//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallSettings {

    struct Audio: Equatable {
        var micOn: Bool
        var speakerOn: Bool
        var audioSessionOn: Bool
    }

    var audio: Audio {
        .init(
            micOn: audioOn,
            speakerOn: speakerOn,
            audioSessionOn: audioOutputOn
        )
    }
}
