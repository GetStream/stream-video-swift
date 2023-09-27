//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

struct MemoryLeaksViewer: View {

    @Injected(\.appearance) var appearance

    @StateObject private var snapshot = MemorySnapshot(
        includeDeallocatedObjects: false,
        includeNotLeaked: false
    )
    @State private var entries: [MemorySnapshot.Entry] = []

    var body: some View {
        List {
            ForEach(entries, id: \.typeName) { entry in
                makeEntryView(for: entry)
            }
        }
        .onReceive(snapshot.$items) { entries = $0 }
        .navigationTitle("MemoryLeaks Viewer")
        .modifier(
            SearchableModifier { query in
                if query.isEmpty {
                    entries = snapshot.items
                } else {
                    entries = snapshot
                        .items
                        .filter { $0.typeName.contains(query) }
                }
            })
    }

    @ViewBuilder
    func makeEntryView(for entry: MemorySnapshot.Entry) -> some View {
        Label {
            HStack {
                Text(entry.typeName)
                    .font(appearance.fonts.body)
                    .foregroundColor(appearance.colors.text)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(entry.refCount)/\(entry.maxCount)")
                    .font(appearance.fonts.caption1)
                    .foregroundColor(appearance.colors.text)
                    .lineLimit(1)
            }
        } icon: {
            if entry.refCount > entry.maxCount {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(appearance.colors.accentRed)
            } else {
                EmptyView()
            }
        }
    }
}
