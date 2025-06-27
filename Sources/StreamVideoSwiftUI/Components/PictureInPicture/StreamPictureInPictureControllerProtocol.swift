//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import Foundation

protocol StreamPictureInPictureControllerProtocol: AnyObject {
    var isPictureInPictureActivePublisher: AnyPublisher<Bool, Never> { get }

    func stopPictureInPicture()
}

extension AVPictureInPictureController: StreamPictureInPictureControllerProtocol {
    var isPictureInPictureActivePublisher: AnyPublisher<Bool, Never> {
        publisher(for: \.isPictureInPictureActive).eraseToAnyPublisher()
    }
}
