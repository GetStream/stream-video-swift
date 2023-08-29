//
//  CallViewModel+CallSettingsPublisher.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/8/23.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import Combine

extension CallViewModel {

    internal var callSettingsPublisher: AnyPublisher<CallSettings, Never> {
        self.$callSettings.eraseToAnyPublisher()
    }
}
