//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

@available(iOS 15.0, *)
enum BackgroundEffect: String, CaseIterable, Identifiable {
    case none
    case blur
    case pixelate
    case blurBackground
    case amsterdam1 = "amsterdam-1"
    case amsterdam2 = "amsterdam-2"
    case boulder1 = "boulder-1"
    case boulder2 = "boulder-2"
    case gradient1 = "gradient-1"
    case gradient2 = "gradient-2"
    case gradient3 = "gradient-3"

    /// Button identity. `NSString` bridging reuses one object for longer
    /// names, so ForEach draws those effects as the blur icon.
    var id: String { rawValue }

    var filter: VideoFilter? {
        switch self {
        case .none:
            return nil
        case .pixelate:
            return .pixelate
        case .blur:
            return .blur
        case .blurBackground:
            return .blurredBackground
        default:
            guard
                let image = UIImage(named: rawValue),
                let ciImage = CIImage(image: image)
            else {
                return nil
            }
            return VideoFilter.imageBackground(ciImage, id: rawValue)
        }
    }

    var image: Image {
        switch self {
        case .none:
            return Image(systemName: "circle.slash")
        case .pixelate:
            return Image(systemName: "square.grid.3x3.square")
        case .blur:
            return Image(systemName: "square.stack.3d.forward.dottedline.fill")
        case .blurBackground:
            return Image(systemName: "square.stack.3d.forward.dottedline")
        default:
            return Image(rawValue)
        }
    }

    var padding: Double {
        switch self {
        case .none:
            return 10
        case .pixelate, .blur, .blurBackground:
            return 10
        default:
            return 0
        }
    }
}
