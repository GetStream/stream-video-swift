//
//  View+OptionalPublisher.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 30/8/23.
//

import Foundation
import SwiftUI
import Combine

extension View {

    @ViewBuilder
    func onReceive<P>(
        _ publisher: P?,
        perform action: @escaping (P.Output) -> Void
    ) -> some View where P : Publisher, P.Failure == Never {
        if let publisher {
            self.onReceive(publisher, perform: action)
        } else {
            self
        }
    }
}
