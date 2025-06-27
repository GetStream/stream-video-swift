//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

#if compiler(>=6.0)
extension CurrentValueSubject: @retroactive @unchecked Sendable {}
extension PassthroughSubject: @retroactive @unchecked Sendable {}
#else
extension CurrentValueSubject: @unchecked Sendable {}
extension PassthroughSubject: @unchecked Sendable {}
#endif
