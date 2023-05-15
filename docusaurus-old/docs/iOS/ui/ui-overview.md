---
title: UI Overview
---

## Introduction

The StreamVideo SDK provides UI components to facilitate the integration of video capabilities into your apps. You can either use our out-of-the-box solution (and customize theming and some views), or completely build your own UI, while reusing our lower level components whenever you see them fit.

The UI components are provided in SwiftUI. If you use UIKit, we also provide UIKit wrappers, that can make it easier for you to integrate video in UIKit based apps.

## StreamVideoUI object

The UI SDK provides a context provider object that allows simple access to functionalities exposed by the SDK, such as branding, presentation logic, icons and the low-level video client.

The `StreamVideoUI` object can be initialized in two ways. The first way is to implicitly create the low-level client `StreamVideo`, by only creating the `StreamVideoUI` object.

```swift
let streamVideoUI = StreamVideoUI(
	apiKey: "your_api_key",
	user: user.userInfo,
	token: user.token,
	videoConfig: VideoConfig(),
	tokenProvider: { result in
		result(.success(user.token))
	}
)
```

The other option is to first create the `StreamVideo` client (in case you want to keep an instance of it), and use that one to create the `StreamVideoUI` object.

```swift
let streamVideo = StreamVideo(
    apiKey: "your_api_key",
    user: user.userInfo,
    token: user.token,
    videoConfig: VideoConfig(),
    tokenProvider: { result in
        result(.success(user.token))
    }
)
let streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
```

It's important to initialize the client early in your app's lifecycle, and as soon as your user is logged in. If you try to display a view without the `StreamVideoUI` object being created, you will receive a crash.

When the object is created, you should connect the user to our backend.

```swift
private func connectUser() {
    Task {
        try await streamVideo?.connect()
    }
}
```

## Customization options

### Appearance

When you create the `StreamVideoUI` object, you can optionally provide your own version of the `Appearance` class, that will allow you to customize things like fonts, colors, icons and sounds used in the SDK.

#### Changing Colors

If you want to change the colors, you can set your own values in the `Colors` class:

```swift
let streamBlue = UIColor(red: 0, green: 108.0 / 255.0, blue: 255.0 / 255.0, alpha: 1)
var colors = Colors()
colors.tintColor = Color(streamBlue)
let appearance = Appearance(colors: colors)
let streamVideo = StreamVideoUI(streamVideo: streamVideo, appearance: appearance)
```

#### Changing Images

All of the images used in the SDK can be replaced with your custom ones. To customize the images, create a new instance of the `Images` class and update the images you want to change. For example, if you want to change the icon for hanging up, you just need to override the corresponding image property.

```swift
var images = Images()
images.hangup = Image("your_custom_hangup_icon")
let appearance = Appearance(images: images)
let streamVideoUI = StreamVideoUI(streamVideo: streamVideo, appearance: appearance)        
```

#### Changing Fonts

You can provide your font to match the style of the rest of your app. In the SDK, the default system font is used, with dynamic type support. To keep this support with your custom fonts, please follow Apple's guidelines about scaling fonts [automatically](https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically).

The fonts used in the SDK can be customized via the `Fonts` struct, which is part of the `Appearance` class. So, for example, if we don't want to use the bold footnote font, we can easily override it with our non-bold version.

```swift
var fonts = Fonts()
fonts.footnoteBold = Font.footnote
let appearance = Appearance(fonts: fonts)
let streamVideoUI = StreamVideoUI(streamVideo: streamVideo, appearance: appearance)
```

#### Changing Sounds

There are several sounds used throughout the video SDK, such as for incoming and outgoing calls. You can change these sounds with your custom ones, by changing the corresponding values in the `Sounds` class:

```swift
let sounds = Sounds()
sounds.incomingCallSound = "your_custom_sound"
let appearance = Appearance(sounds: sounds)
let streamVideoUI = StreamVideoUI(streamVideo: streamVideo, appearance: appearance)
```

### Changing Views

Apart from the basic theming customizations, you can also swap certain views, with your own implementation. You can find more details how to do that on this [page](./customizing-views.md).