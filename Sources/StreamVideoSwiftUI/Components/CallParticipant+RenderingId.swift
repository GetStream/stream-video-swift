//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo

extension CallParticipant {
    
    var renderingId: String {
        "\(trackLookupPrefix ?? id)-\(hasAudio)-\(shouldDisplayTrack)"
    }
}
