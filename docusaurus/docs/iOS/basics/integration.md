---
title: Integration
---

To integrate Stream Video in your app, you can use the [**Swift Package Manager**](#swift-package-manager).

### Swift Package Manager

Open your `.xcodeproj`, select the option "Add Package..." in the File menu, and paste the URL for the library you want to integrate:

- For the LLC (**StreamVideo**) use:
  - `https://github.com/GetStream/stream-video-swift`
- For the SwiftUI components (**StreamVideoSwiftUI**, which depends on **StreamVideo**) use:
  - `https://github.com/GetStream/stream-video-swift`
- For the UIKit components (**StreamVideoUIKit**, which depends on **StreamVideo** and **StreamVideoSwiftUI**) use:
  - `https://github.com/GetStream/stream-video-swift`

After introducing the desired url, Xcode will look for the Packages available in the repository and automatically select the latest version tagged. Press next and Xcode will download the dependency.

Based on the repository you select you can find 3 different targets: StreamVideo, StreamVideoSwiftUI and StreamVideoUIKit.

- If you want to use the SwiftUI components, select **StreamVideoSwiftUI**.
- If you want to use the UIKit components, select **StreamVideoUIKit**.
- If you don't need any UI components, select **StreamVideo**.

After you press finish, it's done!

_More information about Swift Package Manager [can be found here](https://www.swift.org/package-manager/)_