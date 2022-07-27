//
//  TrailingView.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 27.7.22.
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

struct BottomView<Content: View>: View {
    
    var content: () -> Content
    
    var body: some View {
        VStack {
            Spacer()
            content()
        }
    }
    
}
