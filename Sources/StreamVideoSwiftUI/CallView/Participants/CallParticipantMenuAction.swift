//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

public struct CallParticipantMenuAction: Identifiable {
    public var id: String
    public let title: String
    public let requiredCapability: OwnCapability
    public let iconName: String
    public let action: (String) -> Void
    public let confirmationPopup: ConfirmationPopup?
    public let isDestructive: Bool
}

/// Model describing confirmation popup data.
public struct ConfirmationPopup {
    public init(title: String, message: String?, buttonTitle: String) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
    }

    let title: String
    let message: String?
    let buttonTitle: String
}
