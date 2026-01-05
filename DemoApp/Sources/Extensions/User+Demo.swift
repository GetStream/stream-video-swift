//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension User {

    static let builtIn: [User] = {
        [
            (
                "valia",
                "Bernard Windler",
                ""
            ),
            (
                "vasil",
                "Willard Hesser",
                ""
            ),
            (
                "thierry",
                "Thierry",
                "https://ca.slack-edge.com/T02RM6X6B-U02RM6X6D-bc07196e422d-512"
            ),
            (
                "tommaso",
                "Tommaso",
                "https://ca.slack-edge.com/T02RM6X6B-U02U7SJP4-4cd2158d78de-512"
            ),
            (
                "martin",
                "Martin",
                "https://ca.slack-edge.com/T02RM6X6B-U02G45JTM6C-f4884eaf8fdd-72"
            ),
            (
                "ilias",
                "Ilias",
                "https://ca.slack-edge.com/T02RM6X6B-U04LTJUTXFW-bc6e23c4e7ee-72"
            ),
            (
                "alexey",
                "Alexey",
                "https://ca.slack-edge.com/T02RM6X6B-U034BHQ5PT2-9d0c17bccd5a-72"
            ),
            (
                "marcelo",
                "Marcelo",
                "https://ca.slack-edge.com/T02RM6X6B-UD6TCA6P6-3fca649bc81c-72"
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
            User(id: $0.0, name: $0.1, imageURL: $0.2.isEmpty ? nil : URL(string: $0.2))
        }
    }()
}
