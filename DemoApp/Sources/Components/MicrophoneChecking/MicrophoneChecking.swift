//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import Combine

protocol MicrophoneChecking {

    func startListening()

    func stopListening()

    var decibelsPublisher: AnyPublisher<[Float], Never> { get }
}
