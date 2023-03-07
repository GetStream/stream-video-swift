//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {
    public func streamAccessibility(value: String) -> ModifiedContent<Content, Modifier> {
        #if DEBUG
        return self.accessibility(value: Text(value))
        #else
        return self
        #endif
    }
}
