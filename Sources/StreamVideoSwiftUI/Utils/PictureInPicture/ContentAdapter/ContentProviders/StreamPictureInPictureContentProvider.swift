//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

protocol StreamPictureInPictureContentProvider {

    var call: Call? { get set }

    func process(_ content: PictureInPictureDataPipeline.Content)
}
