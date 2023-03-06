//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {
    func streamAccessibility(value: String) -> ModifiedContent<Content, Modifier> {
        #if DEBUG
        self.accessibility(value: Text(value))
        #endif
    }
}
