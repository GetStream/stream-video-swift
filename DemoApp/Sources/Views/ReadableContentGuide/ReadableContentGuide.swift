//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

struct ReadableContentGuideViewModifier: ViewModifier {

    let isEnabled: Bool
    @ScaledMetric private var unit: CGFloat = 20

    func body(content: Content) -> some View {
        // Use a GeometryReader here to get view width.
        GeometryReader { geometryProxy in
            content
                .padding(.horizontal, padding(for: geometryProxy.size.width))
        }
    }

    private func padding(for width: CGFloat) -> CGFloat {
        guard isEnabled else { return 0 }

        // The internet seems to think the optimal readable width is 50-75
        // characters wide; I chose 70 here. The `unit` variable is the
        // approximate size of the system font and is wrapped in
        // @ScaledMetric to better support dynamic type. I assume that
        // the average character width is half of the size of the font.
        let idealWidth = 70 * unit / 2

        // If the width is already readable then don't apply any padding.
        guard width >= idealWidth else {
            return 0
        }

        // If the width is too large then calculate the padding required
        // on either side until the view's width is readable.
        let padding = round((width - idealWidth) / 2)
        return padding
    }
}

extension View {

    @ViewBuilder
    func alignedToReadableContentGuide() -> some View {
        self.modifier(ReadableContentGuideViewModifier(isEnabled: true))
    }
}
