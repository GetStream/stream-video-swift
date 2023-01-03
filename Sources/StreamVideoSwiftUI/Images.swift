//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI
import UIKit

/// Provides access to the images used in the SDK.
public class Images {

    public init() { /* Public init. */ }

    public var videoTurnOn = Image(systemName: "video.fill")
    public var videoTurnOff = Image(systemName: "video.slash.fill")
    public var micTurnOn = Image(systemName: "mic.fill")
    public var micTurnOff = Image(systemName: "mic.slash.fill")
    public var toggleCamera = Image(systemName: toggleCameraImageName)
    public var hangup = Image(systemName: "phone.down.circle.fill")
    public var acceptCall = Image(systemName: "phone.circle.fill")
    public var participants = Image(systemName: "person.2.fill")
    public var xmark = Image(systemName: "xmark")
    public var searchIcon = Image(systemName: "magnifyingglass")
    public var searchCloseIcon = Image(systemName: "multiply.circle")
    public var incomingCallBackground = Image(uiImage: loadImageSafely(with: "incomingCallBackground"))

    private static var toggleCameraImageName: String {
        if #available(iOS 14, *) {
            return "arrow.triangle.2.circlepath.camera.fill"
        } else {
            return "arrow.up.arrow.down"
        }
    }

    /// A private internal function that will safely load an image from the bundle or return a circle image as backup
    /// - Parameter imageName: The required image name to load from the bundle
    /// - Returns: A UIImage that is either the correct image from the bundle or backup circular image
    private static func loadImageSafely(with imageName: String) -> UIImage {
        if let image = UIImage(named: imageName, in: .streamVideoUI, with: nil) {
            return image
        } else {
            log.error(
                """
                \(imageName) image has failed to load from the bundle please make sure it's included in your assets folder.
                A default 'red' circle image has been added.
                """
            )
            return UIImage.circleImage
        }
    }
}
