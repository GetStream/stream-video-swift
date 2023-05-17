//
//  UserAvatar.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 14.3.23.
//

import SwiftUI
import NukeUI

@available(iOS 14.0, *)
public struct UserAvatar: View {
    
    public var imageURL: URL?
    public var size: CGFloat
    
    public init(imageURL: URL?, size: CGFloat) {
        self.imageURL = imageURL
        self.size = size
    }
    
    public var body: some View {
        LazyImage(source: imageURL)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}
