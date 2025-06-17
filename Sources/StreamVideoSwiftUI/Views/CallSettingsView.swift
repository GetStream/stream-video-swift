//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CallSettingsView: View {
    
    @Injected(\.images) var images
    
    @Binding var callSettings: CallSettings
    
    private let iconSize: CGFloat = 50
    
    var body: some View {
        HStack(spacing: 32) {
            Button {
                callSettings = CallSettings(
                    audioOn: !callSettings.audioOn,
                    videoOn: callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            } label: {
                CallIconView(
                    icon: (callSettings.audioOn ? images.micTurnOn : images.micTurnOff),
                    size: iconSize,
                    iconStyle: (callSettings.audioOn ? .primary : .transparent)
                )
                .accessibility(identifier: "microphoneToggle")
                .streamAccessibility(value: callSettings.audioOn ? "1" : "0")
            }

            Button {
                callSettings = CallSettings(
                    audioOn: callSettings.audioOn,
                    videoOn: !callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            } label: {
                CallIconView(
                    icon: (callSettings.videoOn ? images.videoTurnOn : images.videoTurnOff),
                    size: iconSize,
                    iconStyle: (callSettings.videoOn ? .primary : .transparent)
                )
                .accessibility(identifier: "cameraToggle")
                .streamAccessibility(value: callSettings.videoOn ? "1" : "0")
            }
        }
        .padding()
        .debugViewRendering()
    }
}
