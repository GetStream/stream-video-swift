//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideoSwiftUI
import SwiftUI

/// Demo-only “decoration” layers for participant tiles. This mirrors the SDK’s
/// `VideoCallParticipantDecoration` + `applyDecorationModifierIfRequired` pattern, but adds
/// **`demoExtendedMenu`** without modifying StreamVideoSwiftUI (you cannot extend the SDK enum from the app).
///
/// **Mapping**
/// - `sdkStandardMenu` → `VideoCallParticipantDecoration.options` (stock ellipsis menu)
/// - `sdkSpeakingRing` → `VideoCallParticipantDecoration.speaking`
/// - `demoExtendedMenu` → Demo `…` overlay (`DemoExtendedParticipantOptionsView`), not an SDK case
///
/// If both **`sdkStandardMenu`** and **`demoExtendedMenu`** are listed, **`demoExtendedMenu` wins**
/// (duplicate top-left controls are avoided).
enum DemoCallParticipantDecoration: String, Hashable, CaseIterable {
    case sdkStandardMenu
    case sdkSpeakingRing
    case demoExtendedMenu
}

extension DemoCallParticipantDecoration {

    /// Drops `sdkStandardMenu` when `demoExtendedMenu` is enabled.
    static func normalizedSet(_ decorations: [DemoCallParticipantDecoration]) -> Set<DemoCallParticipantDecoration> {
        var set = Set(decorations)
        if set.contains(.demoExtendedMenu) {
            set.remove(.sdkStandardMenu)
        }
        return set
    }
}

extension Set where Element == DemoCallParticipantDecoration {

    /// Subset passed into `VideoCallParticipantModifier`.
    func asVideoCallParticipantDecorations() -> Set<VideoCallParticipantDecoration> {
        var sdk = Set<VideoCallParticipantDecoration>()
        if contains(.sdkStandardMenu) {
            sdk.insert(.options)
        }
        if contains(.sdkSpeakingRing) {
            sdk.insert(.speaking)
        }
        return sdk
    }
}

extension View {

    /// Same idea as `applyDecorationModifierIfRequired` in StreamVideoSwiftUI, for Demo-only modifiers.
    @ViewBuilder
    func applyDemoDecorationModifierIfRequired<M: ViewModifier>(
        _ modifier: @autoclosure () -> M,
        decoration: DemoCallParticipantDecoration,
        availableDecorations: Set<DemoCallParticipantDecoration>
    ) -> some View {
        if availableDecorations.contains(decoration) {
            self.modifier(modifier())
        } else {
            self
        }
    }
}
