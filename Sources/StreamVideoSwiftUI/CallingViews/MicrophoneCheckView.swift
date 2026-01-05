//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct MicrophoneCheckView: View {
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.permissions) var permissions

    var audioLevels: [Float]
    var microphoneOn: Bool
    var isSilent: Bool
    var isPinned: Bool
    var maxHeight: Float = 14

    @State private var hasMicrophoneAccess: Bool

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
        hasMicrophoneAccess = InjectedValues[\.permissions].hasMicrophonePermission
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

            if hasMicrophoneAccess, microphoneOn && !isSilent {
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
        .onReceive(permissions.$hasMicrophonePermission) { hasMicrophoneAccess = $0 }
    }
}

public struct AudioVolumeIndicator: View {
    
    @Injected(\.colors) var colors
    
    var audioLevels: [Float]
    var maxHeight: Float
    var minValue: Float
    var maxValue: Float
    
    public init(
        audioLevels: [Float],
        maxHeight: Float = 14,
        minValue: Float,
        maxValue: Float
    ) {
        self.audioLevels = audioLevels
        self.maxHeight = maxHeight
        self.minValue = minValue
        self.maxValue = maxValue
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(levels) { level in
                VStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colors.goodConnectionQualityIndicatorColor)
                        .frame(width: 2, height: height(for: level.value))
                }
                .frame(height: CGFloat(maxHeight))
            }
        }
    }
    
    var levels: [AudioLevel] {
        var levels = [AudioLevel]()
        for (index, level) in audioLevels.enumerated() {
            levels.append(AudioLevel(value: level, index: index))
        }
        return levels
    }
    
    private func height(for value: Float) -> CGFloat {
        let height: CGFloat = value > 0 ? CGFloat(value * maxHeight) : 0
        return max(height, 1)
    }
}

struct AudioLevel: Identifiable {
    var id: String {
        "\(index)-\(value)"
    }

    let value: Float
    let index: Int
}
