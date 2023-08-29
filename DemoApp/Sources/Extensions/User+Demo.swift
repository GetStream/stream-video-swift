//
//  User+Demo.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/8/23.
//

import Foundation
import StreamVideo

extension User {

    static let builtIn: [User] = {
        [
            (
                "tommaso",
                "Tommaso",
                "https://getstream.io/static/712bb5c0bd5ed8d3fa6e5842f6cfbeed/c59de/tommaso.webp"
            ),
            (
                "marcelo",
                "Marcelo",
                "https://getstream.io/static/aaf5fb17dcfd0a3dd885f62bd21b325a/802d2/marcelo-pires.webp"
            ),
            (
                "martin",
                "Martin",
                "https://getstream.io/static/2796a305dd07651fcceb4721a94f4505/802d2/martin-mitrevski.webp"
            ),
            (
                "filip",
                "Filip",
                "https://getstream.io/static/76cda49669be38b92306cfc93ca742f1/802d2/filip-babi%C4%87.webp"
            ),
            (
                "thierry",
                "Thierry",
                "https://getstream.io/static/237f45f28690696ad8fff92726f45106/c59de/thierry.webp"
            ),
            (
                "sam",
                "Sam",
                "https://getstream.io/static/379eda22663bae101892ad1d37778c3d/802d2/samuel-jeeves.webp"
            ),
            (
                "ilias",
                "Ilias",
                "https://ca.slack-edge.com/T02RM6X6B-U04LTJUTXFW-bc6e23c4e7ee-48"
            )
        ].map {
            User(id: $0.0, name: $0.1, imageURL: URL(string: $0.2))
        }
    }()
}
