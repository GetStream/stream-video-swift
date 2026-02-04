//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension DebugMenu {

    /// Generic debug menu item that selects a single value and can append extra actions.
    struct ItemMenuView<Item: Debuggable, AdditionalItems: View>: View {
        var appState: AppState = .shared

        var items: [Item]
        var currentValue: Item
        var label: String
        var availableAfterLogin: Bool
        var additionalItems: () -> AdditionalItems
        var updater: (Item) -> Void

        init(
            items: [Item],
            currentValue: Item,
            label: String,
            availableAfterLogin: Bool,
            additionalItems: @escaping () -> AdditionalItems,
            updater: @escaping (Item) -> Void
        ) {
            self.items = items
            self.currentValue = currentValue
            self.label = label
            self.availableAfterLogin = availableAfterLogin
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
}

extension DebugMenu.ItemMenuView where AdditionalItems == EmptyView {
    init(
        items: [Item],
        currentValue: Item,
        label: String,
        availableAfterLogin: Bool,
        updater: @escaping (Item) -> Void
    ) {
        self.init(
            items: items,
            currentValue: currentValue,
            label: label,
            availableAfterLogin: availableAfterLogin,
            additionalItems: { EmptyView() },
            updater: updater
        )
    }
}
