//
//  BodyBuildable.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 21/8/26.
//

import SwiftUI

protocol StyleProtocol: AnyObject, Sendable {
    associatedtype Configuration: Equatable
    @MainActor
    func makeBody(configuration: Configuration) -> AnyView
}

@MainActor
struct ApplyStyle<Style: StyleProtocol, Configuration: Equatable>: View where Style.Configuration == Configuration {
    nonisolated(unsafe) var style: Style
    nonisolated(unsafe) var configuration: Configuration

    var body: some View {
        style.makeBody(configuration: configuration)
    }
}

extension ApplyStyle: Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.style === rhs.style && lhs.configuration == rhs.configuration
    }
}
