//
//  AudioFilter.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/8/23.
//

import Foundation
import WebRTC

protocol AudioFilter {

    func applyEffect(to audioBuffer: inout RTCAudioBuffer)
}
