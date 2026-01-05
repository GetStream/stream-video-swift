//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct TrailingView<Content: View>: View {
    
    var content: () -> Content
    
    var body: some View {
        HStack {
            Spacer()
            content()
        }
    }
}

struct TopView<Content: View>: View {
    
    var content: () -> Content
    
    var body: some View {
        VStack {
            content()
            Spacer()
        }
    }
}

/// View container that allows injecting another view in its top left corner.
public struct TopLeftView<Content: View>: View {
    var content: () -> Content

    public init(content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        HStack {
            VStack {
                content()
                Spacer()
            }
            Spacer()
        }
    }
}

/// View container that allows injecting another view in its top right corner.
public struct TopRightView<Content: View>: View {
    var content: () -> Content
    
    public init(content: @escaping () -> Content) {
        self.content = content
    }
        
    public var body: some View {
        HStack {
            Spacer()
            VStack {
                content()
                Spacer()
            }
        }
    }
}

public struct BottomRightView<Content: View>: View {
    var content: () -> Content
    
    public init(content: @escaping () -> Content) {
        self.content = content
    }
        
    public var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                content()
            }
        }
    }
}

public struct BottomView<Content: View>: View {
    
    var content: () -> Content
    
    public init(content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        VStack {
            Spacer()
            content()
        }
    }
}
