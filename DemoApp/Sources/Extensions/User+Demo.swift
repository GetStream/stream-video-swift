//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension User {

    static let builtIn: [User] = {
        [
            (
                "valia",
                "Bernard Windler",
                "https://getstream.io/chat/docs/sdk/avatars/jpg/Bernard%20Windler.jpg"
            ),
            (
                "vasil",
                "Willard Hesser",
                "https://getstream.io/chat/docs/sdk/avatars/jpg/Willard%20Hessel.jpg"
            ),
            (
                "thierry",
                "Thierry",
                "https://getstream.io/static/237f45f28690696ad8fff92726f45106/c59de/thierry.webp"
            ),
            (
                "tommaso",
                "Tommaso",
                "https://getstream.io/static/712bb5c0bd5ed8d3fa6e5842f6cfbeed/c59de/tommaso.webp"
            ),
            (
                "martin",
                "Martin",
                "https://ca.slack-edge.com/T02RM6X6B-U02G45JTM6C-f4884eaf8fdd-512"
            ),
            (
                "ilias",
                "Ilias",
                "https://ca.slack-edge.com/T02RM6X6B-U04LTJUTXFW-bc6e23c4e7ee-512"
            ),
            (
                "alexey",
                "Alexey",
                "https://ca.slack-edge.com/T02RM6X6B-U034BHQ5PT2-9d0c17bccd5a-512"
            ),
            (
                "marcelo",
                "Marcelo",
                "https://getstream.io/static/aaf5fb17dcfd0a3dd885f62bd21b325a/802d2/marcelo-pires.webp"
            ),
            (
                "kanat",
                "Kanat",
                "https://ca.slack-edge.com/T02RM6X6B-U034NG4FPNG-9a37493e25e0-512"
            ),
            (
                "alex",
                "Alex",
                "https://ca.slack-edge.com/T02RM6X6B-U05UD37MA1G-f062f8b7afc2-512"
            )
        ].map {
            User(id: $0.0, name: $0.1, imageURL: URL(string: $0.2))
        }
    }()
}
