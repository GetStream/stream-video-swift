//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

public struct ModalButton: View {

    @Injected(\.colors) var colors

    var image: Image
    var action: () -> Void

    public init(image: Image, action: @escaping () -> Void) {
        self.image = image
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            image
                .resizable()
                .foregroundColor(colors.text)
                .aspectRatio(contentMode: .fit)
                .padding(8)
        }
        .buttonStyle(.modal)
    }
}

struct ModalButtonStyle: ButtonStyle {

    @Injected(\.colors) var colors

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .background(Circle().fill(Color(colors.participantBackground)))
            .frame(width: 30, height: 30)
    }
}

extension ButtonStyle where Self == ModalButtonStyle {

    static var modal: ModalButtonStyle { ModalButtonStyle() }
}
