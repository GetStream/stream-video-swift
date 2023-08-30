//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideoSwiftUI
import Combine

extension MicrophoneChecker: MicrophoneChecking {

    internal var decibelsPublisher: AnyPublisher<[Float], Never> {
        $audioLevels.eraseToAnyPublisher()
    }
}
