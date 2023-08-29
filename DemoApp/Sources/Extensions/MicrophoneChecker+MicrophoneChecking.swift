//
//  MicrophoneChecker+MicrophoneChecking.swift
//  StreamVideoCallApp
//
//  Created by Ilias Pavlidakis on 2/6/23.
//

import Foundation
import StreamVideoSwiftUI
import Combine

extension MicrophoneChecker: MicrophoneChecking {

    internal var decibelsPublisher: AnyPublisher<[Float], Never> {
        $audioLevels.eraseToAnyPublisher()
    }
}
