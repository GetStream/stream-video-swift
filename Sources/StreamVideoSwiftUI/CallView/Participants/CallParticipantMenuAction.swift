//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    public var action: @MainActor @Sendable (String) -> Void
    /// Optional confirmation popup data that may be presented before executing the action.
    public var confirmationPopup: ConfirmationPopup?
    /// A flag indicating whether the action is destructive (e.g., delete).
    public var isDestructive: Bool
}

/// Model describing confirmation popup data.
public struct ConfirmationPopup {
    /// The title of the confirmation popup.
    public var title: String
    /// The optional message displayed in the confirmation popup.
    public var message: String?
    /// The title text for the confirmation button.
    public var buttonTitle: String

    /// Initializes a new confirmation popup.
    /// - Parameters:
    ///   - title: The title of the confirmation popup.
    ///   - message: An optional message to display in the confirmation popup.
    ///   - buttonTitle: The title text for the confirmation button.
    public init(
        title: String,
        message: String?,
        buttonTitle: String
    ) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
    }
}
