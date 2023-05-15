---
title: Background Modes
---

What Are Background Modes?
Background modes are services an app offers that require it to execute tasks when it is not active or running. In the case of VoIP (audio and video) calling apps, enabling background modes can cause the app to update, and execute tasks in the background when the user launches another app or transitions to the home screen. An app may require several background capabilities for different tasks and services, such as audio, video, location, fetch, Bluetooth central, and processing. Check out our [CallKit integration guide](https://staging.getstream.io/video/docs/ios/advanced/callkit-integration/) for more information. 

### How Background Modes Work in Your VoIP App
In the case of your app, assuming user **A** has audio unmuted, video on, and is in an active call with user **B.** When user **A** suspends the app to go into the background, iOS device capabilities, such as the camera and microphone, will not be accessible. In this case,  the system will mute user **A**'s audio, and the picture-in-picture (video) feature will not be available when the app is in the background. The app's inability to access audio and PIP from the background is a default behavior on iOS. To override this default behavior, specify the background modes below so that audio and picture-in-picture become accessible when the app goes to the background.

1. Click the app's name in the Project Navigator, select your target, and go to the **Signing & Capabilities** tab.
2. Enable these capabilities by selecting the following checkboxes.

![Configure background modes](../assets/callkit_01.png)

After enabling these background mode capabilities, unmuted audio will remain unmuted when the app goes into the background. Also, picture-in-picture will be available to the call participant while the app remains in the background. 
