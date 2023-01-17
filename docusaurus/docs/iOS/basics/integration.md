---
title: Integration
---

To integrate Stream Video in your app, you can use the [**Swift Package Manager**](#swift-package-manager).

### Swift Package Manager

In order to add the `StreamVideo` SDK as a Swift Package, follow the following steps:

- In Xcode, go to File -> "Add Packages..."
- Paste the URL https://github.com/GetStream/stream-video-swift.git
- In the option "Dependency Rule" choose "Branch", in the single text input next to it, enter "main"

![Screenshot shows how to add the SPM dependency](../assets/spm.png)

- Choose "Add Package" and wait for the dialog to complete.
- Select `StreamVideo` and `StreamVideoSwiftUI` (if you use SwiftUI, otherwise also select `StreamVideoUIKit`).

![Screenshot shows selection of dependencies](../assets/spm_select.png)

With that, the `StreamVideo` SDK is added to your project.

_More information about Swift Package Manager [can be found here](https://www.swift.org/package-manager/)_