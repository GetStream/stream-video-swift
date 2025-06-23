//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

protocol SDPLineWriter {

    var supportedPrefixes: Set<SupportedPrefix> { get }

    func visit(line: String) -> String
}
