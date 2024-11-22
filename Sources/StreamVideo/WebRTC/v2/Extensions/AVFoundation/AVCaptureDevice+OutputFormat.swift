//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension AVCaptureDevice {
    func outputFormat(
        preferredDimensions: CMVideoDimensions,
        preferredFrameRate: Int
    ) -> AVCaptureDevice.Format? {
        let formats = RTCCameraVideoCapturer
            .supportedFormats(for: self)
            .sorted { $0.areaDiff(preferredDimensions) < $1.areaDiff(preferredDimensions) }

        if let result = formats.first(
            with: [
                .area(preferredDimensions: preferredDimensions),
                .frameRate(preferredFrameRate: preferredFrameRate)
            ]
        ) {
            return result
        } else if let result = formats.first(
            with: [.area(preferredDimensions: preferredDimensions)]
        ) {
            return result
        } else if let result = formats.first(
            with: [.minimumAreaDifference(preferredDimensions: preferredDimensions)]
        ) {
            return result
        } else {
            return nil
        }
    }
}
