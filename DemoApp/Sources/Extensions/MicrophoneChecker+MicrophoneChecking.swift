//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideoSwiftUI

extension MicrophoneChecker {

    var decibelsPublisher: AnyPublisher<[Float], Never> {
        $audioLevels.eraseToAnyPublisher()
    }
}
