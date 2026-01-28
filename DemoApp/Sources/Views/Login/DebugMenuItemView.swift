//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

struct DebugMenuItemView<Item: Debuggable, AdditionalItems: View>: View {

    private var appState = AppState.shared

    var label: String
    var availableAfterLogin: Bool = true
    var items: [Item]
    var currentValue: Item
    var additionalItems: () -> AdditionalItems
    var updater: (Item) -> Void

    init(
        label: String,
        availableAfterLogin: Bool,
        items: [Item],
        currentValue: Item,
        additionalItems: @escaping () -> AdditionalItems = { EmptyView() },
        updater: @escaping (Item) -> Void
    ) {
        self.label = label
        self.availableAfterLogin = availableAfterLogin
        self.items = items
        self.currentValue = currentValue
        self.additionalItems = additionalItems
        self.updater = updater
    }

    var body: some View {
        if !availableAfterLogin, appState.userState == .loggedIn {
            EmptyView()
        } else {
            Menu {
                ForEach(items, id: \.self) { item in
                    Button {
                        updater(item)
                    } label: {
                        Label {
                            Text(item.title)
                        } icon: {
                            currentValue == item
                                ? AnyView(Image(systemName: "checkmark"))
                                : AnyView(EmptyView())
                        }
                    }
                }
                additionalItems()
            } label: {
                Text(label)
            }
        }
    }
}
