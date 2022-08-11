//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    public var toggleCamera = Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
    public var hangup = Image(systemName: "phone.down.circle.fill")
    public var acceptCall = Image(systemName: "phone.circle.fill")
}
