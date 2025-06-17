//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

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
