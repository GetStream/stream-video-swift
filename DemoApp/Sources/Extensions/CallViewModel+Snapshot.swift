//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import UIKit

extension CallViewModel {

    func sendSnapshot(_ snapshot: UIImage) {
        guard
            let resizedImage = resize(image: snapshot, to: .init(width: 30, height: 30)),
            let snapshotData = resizedImage.jpegData(compressionQuality: 0.8)
        else {
            return
        }

        Task {
            do {
                try await call?.sendCustomEvent([
                    "snapshot": .string(snapshotData.base64EncodedString())
                ])
                log.debug("Snapshot was sent successfully ✅")
            } catch {
                log.error("Snapshot failed to  send with error: \(error)")
            }
        }
    }

    private func resize(
        image: UIImage,
        to targetSize: CGSize
    ) -> UIImage? {
        guard
            image.size.width > targetSize.width || image.size.height > targetSize.height
        else {
            return image
        }

        let widthRatio = targetSize.width / image.size.width
        let heightRatio = targetSize.height / image.size.height

        // Determine the scale factor that preserves aspect ratio
        let scaleFactor = min(widthRatio, heightRatio)

        let scaledWidth = image.size.width * scaleFactor
        let scaledHeight = image.size.height * scaleFactor
        let targetRect = CGRect(
            x: (targetSize.width - scaledWidth) / 2,
            y: (targetSize.height - scaledHeight) / 2,
            width: scaledWidth,
            height: scaledHeight
        )

        // Create a new image context
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
        image.draw(in: targetRect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
