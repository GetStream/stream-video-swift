//
//  Modifiers.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 23.7.22.
//

import SwiftUI

extension Image {
    
    public func applyCallButtonStyle(color: Color) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 55)
            .frame(maxHeight: 55)
            .foregroundColor(color)
    }
    
}
