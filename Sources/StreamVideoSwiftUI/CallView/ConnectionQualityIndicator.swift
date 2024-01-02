//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ConnectionQualityIndicator: View {
    
    private var size: CGFloat = 28
    private var width: CGFloat = 3
    
    var connectionQuality: ConnectionQuality
    
    public init(
        connectionQuality: ConnectionQuality,
        size: CGFloat = 28,
        width: CGFloat = 3
    ) {
        self.connectionQuality = connectionQuality
        self.size = size
        self.width = width
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
        .cornerRadius(
            8,
            corners: [.topLeft],
            backgroundColor: connectionQuality == .unknown ? Color.clear : Color.black.opacity(0.6)
        )
        .accessibility(identifier: "connectionQualityIndicator")
    }
    
    private func color(for index: Int) -> Color {
        if connectionQuality == .excellent {
            return .blue
        } else if connectionQuality == .good {
            return index == 3 ? .white : .blue
        } else if connectionQuality == .poor {
            return index == 1 ? .red : .white
        } else {
            return .clear
        }
    }
    
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
