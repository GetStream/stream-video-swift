//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

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
