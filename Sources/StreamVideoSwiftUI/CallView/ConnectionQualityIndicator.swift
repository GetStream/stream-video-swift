//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
/// A view representing a connection quality indicator.
public struct ConnectionQualityIndicator: View {

    @Injected(\.colors) var colors

    private var size: CGFloat = 28
    private var width: CGFloat = 3
    private var paddingsConfig: EdgeInsets

    /// The connection quality represented by this indicator.
    var connectionQuality: ConnectionQuality

    /// Initializes a connection quality indicator with the specified parameters.
    /// - Parameters:
    ///   - connectionQuality: The connection quality to be represented.
    ///   - size: The size of the indicator view.
    ///   - width: The width of each segment in the indicator.
    public init(
        connectionQuality: ConnectionQuality,
        size: CGFloat = 28,
        width: CGFloat = 3,
        paddingsConfig: EdgeInsets = EdgeInsets()
    ) {
        self.connectionQuality = connectionQuality
        self.size = size
        self.width = width
        self.paddingsConfig = paddingsConfig
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(1..<4) { index in
                IndicatorPart(
                    width: width,
                    height: height(for: index),
                    color: color(for: index)
                )
            }
        }
        .frame(width: size, height: size)
        .padding(paddingsConfig)
        .cornerRadius(
            8,
            corners: [.topLeft],
            backgroundColor: connectionQuality == .unknown ? .clear : colors.participantInfoBackgroundColor
        )
        .accessibility(identifier: "connectionQualityIndicator")
    }

    /// Determines the color for a specific indicator part based on the connection quality.
    /// - Parameter index: The index of the indicator part.
    /// - Returns: The color for the specified indicator part.
    private func color(for index: Int) -> Color {
        if connectionQuality == .excellent {
            return colors.goodConnectionQualityIndicatorColor
        } else if connectionQuality == .good {
            return index == 3 ? colors.white : colors.goodConnectionQualityIndicatorColor
        } else if connectionQuality == .poor {
            return index == 1 ? colors.badConnectionQualityIndicatorColor : colors.white
        } else {
            return .clear
        }
    }

    /// Determines the height for a specific indicator part based on its position.
    /// - Parameter part: The part number of the indicator (1, 2, or 3).
    /// - Returns: The height for the specified indicator part.
    private func height(for part: Int) -> CGFloat {
        if part == 1 {
            return width * 2
        } else if part == 2 {
            return width * 3
        } else {
            return width * 4
        }
    }
}

struct IndicatorPart: View {
    
    var width: CGFloat
    var height: CGFloat
    var color: Color
    
    var body: some View {
        RoundedRectangle(cornerSize: .init(width: 2, height: 2))
            .fill(color)
            .frame(width: width, height: height)
    }
}
