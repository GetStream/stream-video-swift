//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct MicrophoneCheckView: View {
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo
    
    var audioLevels: [Float]
    var microphoneOn: Bool
    var isSilent: Bool
    var isPinned: Bool
    var maxHeight: Float = 14
    
    public init(
        audioLevels: [Float],
        microphoneOn: Bool,
        isSilent: Bool,
        isPinned: Bool,
        maxHeight: Float = 14
    ) {
        self.audioLevels = audioLevels
        self.microphoneOn = microphoneOn
        self.isSilent = isSilent
        self.isPinned = isPinned
        self.maxHeight = maxHeight
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if isPinned {
                Image(systemName: "pin.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: CGFloat(maxHeight))
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
            }

            Text(streamVideo.user.name)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(fonts.caption1)
                .minimumScaleFactor(0.7)
                .accessibility(identifier: "participantName")

            if microphoneOn && !isSilent {
                AudioVolumeIndicator(
                    audioLevels: audioLevels,
                    maxHeight: maxHeight,
                    minValue: 0,
                    maxValue: 1
                )
            } else {
                images.micTurnOff
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: CGFloat(maxHeight))
                    .foregroundColor(colors.inactiveCallControl)
            }
        }
        .padding(.all, 2)
        .padding(.horizontal, 4)
        .frame(height: 28)
        .cornerRadius(
            8,
            corners: [.topRight],
            backgroundColor: colors.participantInfoBackgroundColor
        )
        .debugViewRendering()
    }
}
