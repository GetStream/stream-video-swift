//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

public struct MicrophoneCheckView: View {
    @Injected(\.videoAppearance) var videoAppearance
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
        HStack(spacing: tokens.layout.spacingXxs) {
            if isPinned {
                Image(systemName: "pin.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: CGFloat(maxHeight))
                    .foregroundColor(
                        Color(tokens.colors.textOnAccent)
                    )
                    .padding(.trailing, tokens.layout.spacingXxs)
            }

            Text(streamVideo.user.name)
                .foregroundColor(
                    Color(tokens.colors.textOnAccent)
                )
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(tokens.fonts.caption1)
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
                videoAppearance.images.micTurnOff
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: CGFloat(maxHeight))
                    .foregroundColor(
                        Color(tokens.colors.accentError)
                    )
            }
        }
        .padding(.all, tokens.layout.spacingXxxs)
        .padding(.horizontal, tokens.layout.spacingXxs)
        .frame(height: 28)
        .cornerRadius(
            tokens.layout.radiusMd,
            corners: [.topRight],
            backgroundColor: Color(
                tokens.colors.backgroundCoreOverlayDarkStrong
            )
        )
        .onReceive(permissions.$hasMicrophonePermission) { hasMicrophoneAccess = $0 }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

public struct AudioVolumeIndicator: View {
    
    @Injected(\.videoAppearance) var videoAppearance
    
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
        HStack(spacing: tokens.layout.spacingXxxs) {
            ForEach(levels) { level in
                VStack {
                    RoundedRectangle(
                        cornerRadius: tokens.layout.radiusXs
                    )
                    .fill(
                        Color(
                            videoAppearance
                                .colors
                                .indicatorMicrophoneLevelBarActive
                        )
                    )
                    .frame(
                        width: tokens.layout.spacingXxxs,
                        height: height(for: level.value)
                    )
                }
                .frame(height: CGFloat(maxHeight))
            }
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

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
