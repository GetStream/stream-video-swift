//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideoSwiftUI
import Combine

extension MicrophoneChecker {

    internal var decibelsPublisher: AnyPublisher<[Float], Never> {
        $audioLevels.eraseToAnyPublisher()
    }
}
