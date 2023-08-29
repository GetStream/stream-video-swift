//
//  MicrophoneChecking.swift
//  StreamVideoCallCore
//
//  Created by Ilias Pavlidakis on 2/6/23.
//

import Foundation
import Combine

protocol MicrophoneChecking {

    func startListening()

    func stopListening()

    var decibelsPublisher: AnyPublisher<[Float], Never> { get }
}
