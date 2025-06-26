//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftUI

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
