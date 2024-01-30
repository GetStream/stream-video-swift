//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideoSwiftUI

struct DragIndicatorViewModifier: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDragIndicator(.visible)
        } else {
            VStack(spacing: 0) {
                VStack(alignment: .center) {
                    DragHandleView()
                        .padding(.top, 5)
                }.frame(maxWidth: .infinity)

                content
            }
        }
    }
}

extension View {

    @ViewBuilder
    func withDragIndicator() -> some View {
        modifier(DragIndicatorViewModifier())
    }
}
