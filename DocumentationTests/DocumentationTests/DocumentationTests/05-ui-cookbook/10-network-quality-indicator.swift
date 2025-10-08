//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    viewContainer {
        ConnectionQualityIndicator(connectionQuality: participant.connectionQuality)
    }
}
