//
//  View+CVPixelBuffer.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 26/3/25.
//

import Foundation
import SwiftUI

extension View {

    @MainActor
    func toPixelBuffer(contentSize: CGSize) -> CVPixelBuffer? {
        guard #available(iOS 16.0, *) else {
            return nil
        }
        let renderer = ImageRenderer(content: self)
        renderer.proposedSize = .init(contentSize)
        if let image = renderer.uiImage {
            return .build(from: image)
        } else {
            return nil
        }
    }
}

extension CVBuffer: @unchecked @retroactive Sendable {}
