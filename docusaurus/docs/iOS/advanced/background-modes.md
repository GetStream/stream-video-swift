---
title: Background Modes
---
Background modes are services an app offers that require it to execute tasks when it is not active or running. In the case of VoIP (audio and video) calling apps, the background modes may cause the app to enter the background, update, and execute tasks when the user launches another app or transitions to the home screen. These background modes' notifications do not show any visible alert, badge, or play sound. They enable the app suspended in the background to wake up instead. An app may require several background capabilities for different tasks and services, such as audio, location, fetch, Bluetooth central, and processing. When working with VoIP apps, Apple requires you to set three background mode capabilities. To configure these capabilities:

1. Click the app's name in the Project Navigator, select your target, and go to the **Signing & Capabilities** tab.
2. Enable these three capabilities by selecting the following checkboxes.
- **VoIP over IP:** Registers the app to provide VoIP services.
- **Remote notifications:** This enables the app to receive background notifications.
- **Background processing:** Configures the app to benefit from processing time when the user or system events suspend it to the background. When you check this capability, the app resumes running a background fetch.

![Configure background modes](https://github.com/GetStream/stream-video-swift/blob/main/docusaurus/docs/iOS/assets/callkit_01.png)
