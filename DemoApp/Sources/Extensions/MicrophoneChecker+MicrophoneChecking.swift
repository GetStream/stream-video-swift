//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideoSwiftUI

extension MicrophoneChecker {

    internal var decibelsPublisher: AnyPublisher<[Float], Never> {
        $audioLevels.eraseToAnyPublisher()
    }
}
