//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
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

extension View {

    @ViewBuilder
    func onReceive<P>(
        _ publisher: P?,
        perform action: @escaping (P.Output) -> Void
    ) -> some View where P: Publisher, P.Failure == Never {
        if let publisher = publisher {
            onReceive(publisher, perform: action)
        } else {
            self
        }
    }
}
