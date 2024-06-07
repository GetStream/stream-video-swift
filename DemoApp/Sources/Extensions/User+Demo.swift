//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension User {

    static let builtIn: [User] = {
        [
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
                "https://getstream.io/static/2796a305dd07651fcceb4721a94f4505/802d2/martin-mitrevski.webp"
            ),
            (
                "ilias",
                "Ilias",
                "https://getstream.io/static/62cdddcc7759dc8c3ba5b1f67153658c/802d2/ilias-pavlidakis.webp"
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
            ),
            (
                "valia",
                "Bernard Windler",
                "https://getstream.io/chat/docs/sdk/avatars/jpg/Bernard%20Windler.jpg"
            ),
            (
                "vasil",
                "Willard Hesser",
                "https://getstream.io/chat/docs/sdk/avatars/jpg/Willard%20Hessel.jpg"
            )
        ].map {
            User(id: $0.0, name: $0.1, imageURL: URL(string: $0.2))
        }
    }()
}
