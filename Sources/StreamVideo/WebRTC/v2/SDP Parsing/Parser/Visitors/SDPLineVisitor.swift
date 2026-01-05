//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

protocol SDPLineVisitor {

    var supportedPrefixes: Set<SupportedPrefix> { get }

    func visit(line: String)
}
