//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension View {

    @ViewBuilder
    public func applyDecorationModifierIfRequired<Modifier: ViewModifier>(
        _ modifier: @autoclosure () -> Modifier,
        decoration: VideoCallParticipantDecoration,
        availableDecorations: Set<VideoCallParticipantDecoration>
    ) -> some View {
        if availableDecorations.contains(decoration) {
            self.modifier(modifier())
        } else {
            self
        }
    }
}
