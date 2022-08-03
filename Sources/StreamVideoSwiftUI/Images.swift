//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import UIKit
import SwiftUI

/// Provides access to the images used in the SDK.
public class Images {
    
    public init() { /* Public init. */ }
    
    public var videoTurnOn = Image(systemName: "video.fill")
    public var videoTurnOff = Image(systemName: "video.slash.fill")
    public var micTurnOn = Image(systemName: "mic.circle.fill")
    public var micTurnOff = Image(systemName: "mic.slash.circle.fill")
    public var toggleCamera = Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
    public var hangup = Image(systemName: "phone.circle.fill")
}
