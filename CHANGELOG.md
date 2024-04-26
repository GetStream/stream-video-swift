# StreamVideo iOS SDK CHANGELOG

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

# Upcoming

### 🔄 Changed
- The return type of `call.get()` is now the API type `GetCallResponse` which encapsulates the previous `CallResponse` under the `call` property. [#335](https://github.com/GetStream/stream-video-swift/pull/335)
- Remove Nuke dependency from the SwiftUI SDK. [#340](https://github.com/GetStream/stream-video-swift/pull/340)
- `members` type changed from `MemberRequest` to `Member` in `startCall` and `enterLobby` in `CallViewModel`.

### ✅ Added
- The SDK now provides a CallKit integration out of the box. [#334](https://github.com/GetStream/stream-video-swift/pull/334)
- Infrastructure required for NoiseCancellation support [#353](https://github.com/GetStream/stream-video-swift/pull/353)
- User `call_display_name` property from VoIP push notifications, whenever is available [#361](https://github.com/GetStream/stream-video-swift/pull/361)

### 🐞 Fixed
- An issue where VoIP push notifications for ended calls, were received when the user connects [#336](https://github.com/GetStream/stream-video-swift/pull/336)

# [0.5.3](https://github.com/GetStream/stream-video-swift/releases/tag/0.5.3)
_March 19, 2024_

### 🐞 Fixed
- CallView positioning when placed inside a UIKit container. [#329](https://github.com/GetStream/stream-video-swift/pull/329) 

# [0.5.2](https://github.com/GetStream/stream-video-swift/releases/tag/0.5.2)
_March 15, 2024_

### ✅ Added
- Stats reporting. [#313](https://github.com/GetStream/stream-video-swift/pull/313)

# [0.5.1](https://github.com/GetStream/stream-video-swift/releases/tag/0.5.1)
_March 05, 2024_

### ✅ Added
- New API that allows adding/removing capturePhotoOutput, videoOutput on the local participant's AVCaptureSession. [#301](https://github.com/GetStream/stream-video-swift/pull/301)
- New API that allows zooming the local participant's camera. [#301](https://github.com/GetStream/stream-video-swift/pull/301)
- VideoFilters for blurring or setting an image as background. [#309](https://github.com/GetStream/stream-video-swift/pull/309)

### 🐞 Fixed
- Updated Web Socket reconnection logic. [#314](https://github.com/GetStream/stream-video-swift/pull/314)

# [0.5.0](https://github.com/GetStream/stream-video-swift/releases/tag/0.5.0)
_February 15, 2024_

### 🔄 Changed

- The following API changes occurred as part of the redesign. [#269](https://github.com/GetStream/stream-video-swift/pull/269) & [#270](https://github.com/GetStream/stream-video-swift/pull/270)
    - `OutgoingCallView` now accepts an additional `callTopView` parameter to align with the updated design.
    - `CallParticipantsInfoView` and the `ViewFactory.makeParticipantsListView` method aren't accept the `availableFrame` anymore.
    - `ParticipantsGridLayout` `orientation` parameter isn't required anymore.
    - The `onRotate` ViewModifier has been removed. You can use the `InjectedValues[\.orientationAdapter]` which is an ObservableObject that can provide information regarding device orientation.

# [0.4.2](https://github.com/GetStream/stream-video-swift/releases/tag/0.4.2)
_December 08, 2023_

### ⚠️ Important

- Nuke dependency is no longer exposed. If you were using this dependency we were exposing, you would need to import it manually. This is due to our newest addition supporting Module Stable XCFramework, see more below in the "Added" section. If you encounter any SPM-related problems, be sure to reset the package caches.

### ✅ Added
- Add support for pre-built XCFrameworks
- Fast reconnection
- New redesigned UI components. [#236](https://github.com/GetStream/stream-video-swift/pull/236)

### 🔄 Changed
- You can now focus on a desired point in the local video stream. [#221](https://github.com/GetStream/stream-video-swift/pull/221)
- The following API changes occurred as part of the redesign. [#221](https://github.com/GetStream/stream-video-swift/pull/221)
    - `CornerDragableView` has been renamed to `CornerDraggableView` and initializer changed.
    - `LocalParticipantViewModifier` & `VideoCallParticipantModifier` now accept a few parameters that allow you to further control their presentation.
    - `ScreenSharingView` now accepts a `isZoomEnabled` parameter to control if the the view will be zoom-able.
    - `LocalVideoView` now accepts a `availableFrame` parameter.

# [0.4.1](https://github.com/GetStream/stream-video-swift/releases/tag/0.4.1)
_October 16, 2023_

### 🐞 Fixed
- Video tracks remain disabled when they become visible [#191](https://github.com/GetStream/stream-video-swift/pull/191)

# [0.4.0](https://github.com/GetStream/stream-video-swift/releases/tag/0.4.0)
_October 11, 2023_

### ✅ Added
- Picture-in-Picture support
- Livestream Player
- Call stats report

### 🔄 Changed
- Factory method for creating `LocalParticipantViewModifier`
- `availableSize` has been replaced by `availableFrame` in most Views.

### 🐞 Fixed
- Current user overlay view size when camera is off
- Thermal state improvements
- Benchmark tests for up to 1000 users

# [0.3.0](https://github.com/GetStream/stream-video-swift/releases/tag/0.3.0)
_August 25, 2023_

### ✅ Added
- Screensharing from iOS devices
- Remote pinning of users
- Add XCPrivacy manifest
- Custom Audio Filters

### 🔄 Changed
- Factory method for creating `VideoCallParticipantView`
- `VideoCallParticipantView` init method

### 🐞 Fixed
- Stability improvements
- CPU usage improvements

# [0.2.0](https://github.com/GetStream/stream-video-swift/releases/tag/0.2.0)
_July 18, 2023_

### ✅ Added
- SDK version info sent in all requests
- Call participants shown in the lobby view
- Support for setting default audio device
- Improved test coverage

# [0.1.0](https://github.com/GetStream/stream-video-swift/releases/tag/0.1.0)
_July 07, 2023_

### ✅ Added

- StreamVideo iOS SDK 🚀
