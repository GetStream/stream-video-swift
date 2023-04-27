---
title: User Avatar
---

The user avatar is available as a standalone component, that you can use in your custom UI. The SwiftUI view is called `UserAvatar` and it's created with the image url and the size.

Here's an example usage:

```swift
var body: some View {
    VStack {
        UserAvatar(imageURL: participant.profileImageURL, size: 40)
        SomeOtherView()
    }
}
```

The view has a circled shape. If that does not fit your UI requirements, you can easily build your own view, by either using the native `AsyncImage`, or `Nuke`'s `LazyImage`.