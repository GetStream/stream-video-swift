//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import Combine

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
    ) -> some View where P : Publisher, P.Failure == Never {
        if let publisher = publisher {
            self.onReceive(publisher, perform: action)
        } else {
            self
        }
    }
}
