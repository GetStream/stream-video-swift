//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension Alert {
    public static var defaultErrorAlert: Alert {
        Alert(
            title: Text(L10n.Alert.Error.title),
            message: Text(L10n.Alert.Error.message),
            dismissButton: .cancel(Text(L10n.Alert.Actions.ok))
        )
    }
}
