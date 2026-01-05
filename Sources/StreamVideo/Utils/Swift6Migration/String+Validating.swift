//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension String {

    #if compiler(>=6.0)
    init?(validatingUTF8 cString: UnsafePointer<CChar>) {
        self.init(validatingCString: cString)
    }
    #endif
}
