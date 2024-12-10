//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

protocol SDPLineVisitor {

    var supportedPrefixes: Set<SupportedPrefix> { get }

    func visit(line: String)
}
