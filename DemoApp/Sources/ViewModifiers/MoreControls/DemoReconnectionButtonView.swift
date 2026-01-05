//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoReconnectionButtonView: View {

    private enum ReconnectStrategy: String { case fast, rejoin, migrate }

    @State private var isActive: Bool = false
    private var dismissMoreMenu: () -> Void

    init(_ dismissMoreMenu: @escaping () -> Void) {
        self.dismissMoreMenu = dismissMoreMenu
    }

    var body: some View {
        Menu {
            buttonView(for: .fast)
            buttonView(for: .rejoin)
            buttonView(for: .migrate)
        } label: {
            DemoMoreControlListButtonView(
                action: { isActive.toggle() },
                label: "Reconnect"
            ) {
                Image(
                    systemName: isActive
                        ? "ladybug"
                        : "ladybug.fill"
                )
            }
        }
    }

    @ViewBuilder
    private func buttonView(
        for reconnectStrategy: ReconnectStrategy
    ) -> some View {
        let (title, icon): (String, String) = {
            switch reconnectStrategy {
            case .fast:
                return ("Fast", "hare")
            case .rejoin:
                return ("Rejoin", "arrow.clockwise.circle")
            case .migrate:
                return ("Migrate", "arrowshape.zigzag.right")
            }
        }()

        Button {
            execute(reconnectStrategy)
        } label: {
            Label { Text(title) } icon: { Image(systemName: icon) }
        }
    }

    private func execute(
        _ reconnectStrategy: ReconnectStrategy
    ) {
        let notificationName = [
            "video",
            "getstream.io",
            "reconnect",
            reconnectStrategy.rawValue
        ].joined(separator: ".")

        NotificationCenter
            .default
            .post(
                name: .init(notificationName),
                object: nil
            )
        
        dismissMoreMenu()
    }
}
