//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

enum HuddleTrack: String, CaseIterable {
    case trackA = "huddle-song-1"
    case trackB = "huddle-song-2"

    var fileExtension: String {
        "mp3"
    }

    var url: URL? {
        Bundle.main.url(
            forResource: rawValue,
            withExtension: fileExtension
        )
    }

    var exists: Bool {
        url != nil
    }
}
