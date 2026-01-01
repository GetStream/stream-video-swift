//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVCaptureDevice.Format {
    /// The media subtype associated with the format description.
    ///
    /// This represents the FourCharCode describing the pixel format or media
    /// encoding (e.g., '420v' for NV12). Useful for identifying the format
    /// used by a capture device.
    var mediaSubType: FourCharCode { CMFormatDescriptionGetMediaSubType(formatDescription) }
}
