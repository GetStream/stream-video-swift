//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

/// Represents an action available in the menu for a call participant.
public struct CallParticipantMenuAction: Identifiable {
    /// The unique identifier for the action.
    public var id: String
    /// The title of the menu action.
    public var title: String
    /// The required capability to execute this action.
    public var requiredCapability: OwnCapability
    /// The name of the icon associated with the action.
    public var iconName: String
    /// The closure to execute when the action is triggered, passing the participant's ID.
    public var action: @MainActor @Sendable(String) -> Void
    /// Optional confirmation popup data that may be presented before executing the action.
    public var confirmationPopup: ConfirmationPopup?
    /// A flag indicating whether the action is destructive (e.g., delete).
    public var isDestructive: Bool
}
