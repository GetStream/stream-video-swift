//
//  SampleBufferVideoCallView.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 30.8.23.
//

import UIKit
import AVKit

class SampleBufferVideoCallView: UIView {
    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }
    
    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        return layer as! AVSampleBufferDisplayLayer
    }
}
