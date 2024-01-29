import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    container {
        ConnectionQualityIndicator(connectionQuality: participant.connectionQuality)
    }
}
