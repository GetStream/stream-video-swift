//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

extension View {

    @ViewBuilder
    func onReceive<P>(
        _ publisher: P?,
        perform action: @escaping (P.Output) -> Void
    ) -> some View where P : Publisher, P.Failure == Never {
        if let publisher {
            self.onReceive(publisher, perform: action)
        } else {
            self
        }
    }
}
