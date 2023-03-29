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
    public var speakerOn = Image(systemName: "speaker.wave.3.fill")
    public var speakerOff = Image(systemName: "speaker.slash.fill")
    public var toggleCamera = Image(systemName: toggleCameraImageName)
    public var hangup = Image(systemName: "phone.down.circle.fill")
    public var acceptCall = Image(systemName: "phone.circle.fill")
    public var participants = Image(systemName: "person.2.fill")
    public var xmark = Image(systemName: "xmark")
    public var searchIcon = Image(systemName: "magnifyingglass")
    public var searchCloseIcon = Image(systemName: "multiply.circle")
    
    private static var toggleCameraImageName: String {
        if #available(iOS 14, *) {
            return "arrow.triangle.2.circlepath.camera.fill"
        } else {
            return "arrow.up.arrow.down"
        }
    }
}
