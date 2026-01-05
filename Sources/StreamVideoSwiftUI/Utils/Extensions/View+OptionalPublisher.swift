//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

extension View {

    @ViewBuilder
    public func onReceive<P>(
        _ publisher: P?,
        perform action: @escaping (P.Output) -> Void
    ) -> some View where P: Publisher, P.Failure == Never {
        if let publisher {
            onReceive(publisher, perform: action)
        } else {
            self
        }
    }
}
