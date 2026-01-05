# StreamVideo iOS SDK CHANGELOG

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

# Upcoming

### 🔄 Changed

# [1.39.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.39.0)
_December 24, 2025_

### ✅ Added
- Support for capture inApp audio during ScreenSharing sessions. [#1020](https://github.com/GetStream/stream-video-swift/pull/1020)

# [1.38.2](https://github.com/GetStream/stream-video-swift/releases/tag/1.38.2)
_December 22, 2025_

### 🔄 Changed
- Improve reconnection logic. [#1013](https://github.com/GetStream/stream-video-swift/pull/1013)

# [1.38.1](https://github.com/GetStream/stream-video-swift/releases/tag/1.38.1)
_December 15, 2025_

### ✅ Added
- Configuration in `CallKitAdapter` to skip calls from showing in the `Recents` app. [#1008](https://github.com/GetStream/stream-video-swift/pull/1008)

### 🐞 Fixed
- An issue causing the local participant waveform to activate while the local participant wasn't speaking. [#1009](https://github.com/GetStream/stream-video-swift/pull/1009)

# [1.38.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.38.0)
_December 09, 2025_

### ✅ Added
- Improved support for moderation events handling. [#1004](https://github.com/GetStream/stream-video-swift/pull/1004)

### 🐞 Fixed
- Pass the missing rejection reason to API calls. [#1003](https://github.com/GetStream/stream-video-swift/pull/1003)
- Mic and camera prompts showing up when not necessary. [#1005](https://github.com/GetStream/stream-video-swift/pull/1005)

# [1.37.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.37.0)
_November 28, 2025_

### ✅ Added
- A Livestream focused AudioSessionPolicy that has support for stereo playout. [#975](https://github.com/GetStream/stream-video-swift/pull/975)

# [1.36.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.36.0)
_November 19, 2025_

### ✅ Added
- Add support for ringing individual members. [#995](https://github.com/GetStream/stream-video-swift/pull/995)

### 🐞 Fixed
- Ensure SFU track and participant updates create missing participants. [#996](https://github.com/GetStream/stream-video-swift/pull/996)

# [1.35.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.35.0)
_November 05, 2025_

### ✅ Added
- SwiftUI modifiers that surface moderation blur and warning events in `CallView`. [#987](https://github.com/GetStream/stream-video-swift/pull/987)

# [1.34.2](https://github.com/GetStream/stream-video-swift/releases/tag/1.34.2)
_October 24, 2025_

### 🔄 Changed

- Update WebRTC to 137.0.42 which brings performance improvements on video rendering. [#983](https://github.com/GetStream/stream-video-swift/pull/983)

# [1.34.1](https://github.com/GetStream/stream-video-swift/releases/tag/1.34.1)
_October 14, 2025_

### 🐞 Fixed
- An issue that was causing the speaker to toggle nonstop. [#968](https://github.com/GetStream/stream-video-swift/pull/968)

# [1.34.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.34.0)
_October 07, 2025_

### 🔄 Changed
- Permissions prompts won't show up when moving to background for a call that has already ended but the feedback screen is visible. [#951](https://github.com/GetStream/stream-video-swift/pull/951)

# [1.33.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.33.0)
_September 15, 2025_

### 🔄 Changed
- Updated WebRTC version to 135.0.41. [#942](https://github.com/GetStream/stream-video-swift/pull/942)
- Reworked the AudioFilter pipeline to be more robust and flexible. [#942](https://github.com/GetStream/stream-video-swift/pull/942)
- **Breaking** `StreamAudioFilterProcessingModule`, `AudioFilterCapturePostProcessingModule`, `StreamAudioFilterCapturePostProcessingModule` have been removed. [#942](https://github.com/GetStream/stream-video-swift/pull/942)

# [1.32.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.32.0)
_September 08, 2025_

### ✅ Added
- When the user is missing a permission, the SDK will prompt them to accept any missing permission. [#915](https://github.com/GetStream/stream-video-swift/pull/915)
- You can now set the `ViewFactory` instance to be used from Picture-in-Picture. [#934](https://github.com/GetStream/stream-video-swift/pull/934)
- `CallParticipant` now exposes the `source` property, which can be used to distinguish between WebRTC users and ingest sources like RTMP or SIP. [#93](https://github.com/GetStream/stream-video-swift/pull/933)
- Add the user action to kick a participant from a call. [#928](https://github.com/GetStream/stream-video-swift/pull/928)

### 🔄 Changed
- Improved the LastParticipantLeavePolicy to be more robust. [#925](https://github.com/GetStream/stream-video-swift/pull/925)

# [1.31.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.31.0)
_August 21, 2025_

### 🐞 Fixed
- An issue that was causing the local participant's audio waveform visualization to stop working. [#912](https://github.com/GetStream/stream-video-swift/pull/912)
- Proximity policies weren't updating CallSettings correctly. That would cause issues where Speaker may not be reenabled or video not being stopped/restarted when proximity changes. [#913](https://github.com/GetStream/stream-video-swift/pull/913)

# [1.30.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.30.0)
_August 08, 2025_


### ✅ Added
- The SDK now handles the interruptions produced from AVCaptureSession to ensure video capturing is active when needed. [#907](https://github.com/GetStream/stream-video-swift/pull/907)

### 🐞 Fixed
- AudioSession management issues that were causing audio not being recorded during calls. [#906](https://github.com/GetStream/stream-video-swift/pull/906)

# [1.29.1](https://github.com/GetStream/stream-video-swift/releases/tag/1.29.1)
_July 25, 2025_

### 🐞 Fixed
- An issue that caused the CallViewModel to end outgoing group calls prematurely when a participant rejected the call. [#901](https://github.com/GetStream/stream-video-swift/pull/901)

# [1.29.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.29.0)
_July 21, 2025_

### ✅ Added
- `ClientCapabilities` have been added to support remote subscriber track pause. [#888](https://github.com/GetStream/stream-video-swift/pull/888)

### 🐞 Fixed
- An issue causing a reconnection loop when connection was recoevered. [#895](https://github.com/GetStream/stream-video-swift/pull/895)

# [1.28.1](https://github.com/GetStream/stream-video-swift/releases/tag/1.28.1)
_July 11, 2025_

### 🐞 Fixed
- Fix an issue where CallKit audio was not functioning properly. [#885](https://github.com/GetStream/stream-video-swift/pull/885)

# [1.28.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.28.0)
_July 01, 2025_

### 🔄 Changed
- Performance improvements around timers. [#877](https://github.com/GetStream/stream-video-swift/pull/877)
- Improve VideoCapturer handling [#872](https://github.com/GetStream/stream-video-swift/pull/872)

### 🐞 Fixed
- An issue causing the CallSettings to be misaligned with the UI components. [#882](https://github.com/GetStream/stream-video-swift/pull/882)

# [1.27.2](https://github.com/GetStream/stream-video-swift/releases/tag/1.27.2)
_June 25, 2025_

### 🐞 Fixed
- Fix an issue causing video not showing in some scenarios. [#870](https://github.com/GetStream/stream-video-swift/pull/870)

# [1.27.1](https://github.com/GetStream/stream-video-swift/releases/tag/1.27.1)
_June 25, 2025_

### 🐞 Fixed
- Reconnection loop when a user tries to rejoin an ended call but they don't have permissions to join ended calls. [#864](https://github.com/GetStream/stream-video-swift/pull/864)
- When receiving calls while the app is not running, the Call layout may appear wrong for 1:1 calls. [#863](https://github.com/GetStream/stream-video-swift/pull/863)

# [1.27.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.27.0)
_June 23, 2025_

### 🔄 Changed
- Performance improvements. [#861](https://github.com/GetStream/stream-video-swift/pull/861)

### ✅ Added
- Support for receiving stereo audio. [#860](https://github.com/GetStream/stream-video-swift/pull/860)

# [1.26.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.26.0)
_June 19, 2025_

### ✅ Added
- `UIApplication.shared.isIdleTimerDisabled` handling is now happening on the SDK, removing the need to do it on UI level. [#853](https://github.com/GetStream/stream-video-swift/pull/853)

### 🔄 Changed
- Improved behavior in bad-network conditions. [#852](https://github.com/GetStream/stream-video-swift/pull/852)

### 🐞 Fixed
- CallKit ending 1:1 calls prematurely. [#850](https://github.com/GetStream/stream-video-swift/pull/850)
- Fixed an issue that was causing confusion to the shared AudioSession object when multiple Call instances are in memory. [#852](https://github.com/GetStream/stream-video-swift/pull/852)

# [1.25.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.25.0)
_June 16, 2025_

### 🐞 Fixed
- The CallViewModel will now respect the dashboard's `CallSettings` when starting a `Call` with `ring:true` and without provided `CallSettings`. [#841](https://github.com/GetStream/stream-video-swift/pull/841)

# [1.24.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.24.0)
_June 02, 2025_

### ✅ Added
- Stats V2 reporting. [#806](https://github.com/GetStream/stream-video-swift/pull/806)
- `CallViewController` was updated to accept the `video` flag when starting a call. [#811](https://github.com/GetStream/stream-video-swift/pull/811)
- `team` property when creating calls through `CallViewModel` and/or `CallViewController` [#817](https://github.com/GetStream/stream-video-swift/pull/817)

### 🔄 Changed
- When joining a Call, if the user has an external audio device connected, we will ignore the remote `CallSettings.speakerOn = true`. [#819](https://github.com/GetStream/stream-video-swift/pull/819)
- CallKit will report correctly the rejection reason when ringing timeout is reached. [#820](https://github.com/GetStream/stream-video-swift/pull/820)

### 🐞 Fixed
- Fix a retain cycle that was causing StreamVideo to leak in projects using NoiseCancellation. [#814](https://github.com/GetStream/stream-video-swift/pull/814)
- Fix occasional crash caused inside `MicrophoneChecker`. [#813](https://github.com/GetStream/stream-video-swift/pull/813)
- Fix `video` parameter wasn't respected when creating Calls, causing CallKit notifications to always show a call as `audio`. [#818](https://github.com/GetStream/stream-video-swift/pull/818)

# [1.22.2](https://github.com/GetStream/stream-video-swift/releases/tag/1.22.2)
_May 13, 2025_

### 🐞 Fixed
- Fix an issue that was causing CallSettings misalignment during reconnection [#810](https://github.com/GetStream/stream-video-swift/pull/810)
- Synchronize CallKit audioSession with the audioSession in the app. [#807](https://github.com/GetStream/stream-video-swift/pull/807)

# [1.22.1](https://github.com/GetStream/stream-video-swift/releases/tag/1.22.1)
_May 08, 2025_

### 🐞 Fixed
- Fix an issue that when the app was becoming active from the application switcher, Picture-in-Picture wasn't stopped. [#803](https://github.com/GetStream/stream-video-swift/pull/803)

### 🔄 Changed
- Update OutgoingCallView to get updates from ringing call [#798](https://github.com/GetStream/stream-video-swift/pull/798)

# [1.22.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.22.0)
_May 05, 2025_

### ✅ Added
- You can now configure policies based on the the device's proximity information. Those policies can be used to toggle speaker and video. [#770](https://github.com/GetStream/stream-video-swift/pull/770)

### 🐞 Fixed
- Fix ringing flow issues. [#792](https://github.com/GetStream/stream-video-swift/pull/792)
- Fix a few points that were negatively affecting Picture-in-Picture lifecycle. [#796](https://github.com/GetStream/stream-video-swift/pull/796)

# [1.21.1](https://github.com/GetStream/stream-video-swift/releases/tag/1.21.1)
_April 25, 2025_

### 🔄 Changed
- Improved the flow of joining a call [#747](https://github.com/GetStream/stream-video-swift/pull/747)

### 🐞 Fixed
- Fix an issue causing audio/video misalignment with the server. [#772](https://github.com/GetStream/stream-video-swift/pull/772)
- Fix an issue causing the speaker to mute when video was off. [#771](https://github.com/GetStream/stream-video-swift/pull/771)

# [1.21.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.21.0)
_April 22, 2025_

### ✅ Added
- Countdown timer and waiting participants info to the livestream player [#754](https://github.com/GetStream/stream-video-swift/pull/754)
- EventPublisher for `Call` objects. [#759](https://github.com/GetStream/stream-video-swift/pull/759)
- You can now access the `custom-data` attached on a Call object you received as incoming. [#766](https://github.com/GetStream/stream-video-swift/pull/766)

### 🔄 Changed
- `CallViewModel.callingState` transition to `.idle` just before moving to `.inCall` after the user has accepted the call. [#759](https://github.com/GetStream/stream-video-swift/pull/759)
- `AudioSession` mode wasn't configured correctly for audio-only calls. [#762](https://github.com/GetStream/stream-video-swift/pull/762)
- Updated WebRTC version to 125.6422.070 [#760](https://github.com/GetStream/stream-video-swift/pull/760)
- Picture-in-Picture improved UI and stability fixes. [#724](https://github.com/GetStream/stream-video-swift/pull/724)

### 🐞 Fixed
- Sound resources weren't loaded correctly when the SDK was linked via SPM. [#757](https://github.com/GetStream/stream-video-swift/pull/757)
- Redefined the priorities by which dashboard audio settings will be applied. [#758](https://github.com/GetStream/stream-video-swift/pull/758)

# [1.20.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.20.0)
_April 07, 2025_

### 🔄 Changed
- Updated WebRTC version to 125.6422.066 [#748](https://github.com/GetStream/stream-video-swift/pull/748)

### 🐞 Fixed
- CallKit should only handle the CallAccepted events that match the userId of the current user. [#733](https://github.com/GetStream/stream-video-swift/pull/733)
- During a reconnection/migration the current user will not be appearing twice any more. [#731](https://github.com/GetStream/stream-video-swift/pull/731)
- ParticipantsCount and AnonymousParticipantsCount weren't updating correctly. [#736](https://github.com/GetStream/stream-video-swift/pull/736)
- Fast reconnection flow was unable to recover subscriber connections. [#741](https://github.com/GetStream/stream-video-swift/pull/741)
- CallSettings weren't set correctly (either when you were passing manually or from dashboard) when a call was joined without setting the create flag to `true`. [#745](https://github.com/GetStream/stream-video-swift/pull/745)
- Resolves a potential issue that was could cause the WebSocketClient to crash when deallocating. [#746](https://github.com/GetStream/stream-video-swift/pull/746)

# [1.19.2](https://github.com/GetStream/stream-video-swift/releases/tag/1.19.2)
_March 27, 2025_

### 🐞 Fixed
- SPM dependency for SwiftProtobuf was outdated and sometimes Xcode couldn't fetch the latest required version. [#730](https://github.com/GetStream/stream-video-swift/pull/730)

# [1.19.1](https://github.com/GetStream/stream-video-swift/releases/tag/1.19.1)
_March 25, 2025_

### 🐞 Fixed
- Fix an issue that was keeping the Picture-in-Picture active while the app was in the foreground [#723](https://github.com/GetStream/stream-video-swift/pull/723)
- Update WebRTC to resolve a crash on HangUp [#727](https://github.com/GetStream/stream-video-swift/pull/727)

# [1.19.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.19.0)
_March 20, 2025_

### 🐞 Fixed
- Fix an issue that was stopping NoiseCancellation from being activated [#705](https://github.com/GetStream/stream-video-swift/pull/705)
- Fix an issue where SetPublisher request was firing when nothing was published [#706](https://github.com/GetStream/stream-video-swift/pull/706)
- The VideoRendererView for the localParticipant, will flip **only** the front camera feed, not the back one [#708](https://github.com/GetStream/stream-video-swift/pull/708)
- Attempt to fix a race condition caused in the MicrophoneChecker. [#718](https://github.com/GetStream/stream-video-swift/pull/718)

### ✅ Added
- Better handling for blocked users [#707](https://github.com/GetStream/stream-video-swift/pull/707)

### ✅ Added
- Expose publicly the `StreamPictureInPictureAdapter` so it can be used outside of the `CallViewModel` [#711](https://github.com/GetStream/stream-video-swift/pull/711)

# [1.18.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.18.0)
_March 06, 2025_

### ✅ Added
- Support for Swift 6 [#684](https://github.com/GetStream/stream-video-swift/pull/684)

### 🐞 Fixed
- Fix a race condition caused in the MicrophoneChecker. [#700](https://github.com/GetStream/stream-video-swift/pull/700)

# [1.17.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.17.0)
_February 14, 2025_

### ✅ Added
- You can now configure the policy used by SDK's AudioSession. `DefaultAudioSessionPolicy` is meant to be used for active participants in a call (1:1, group calls) and `OwnCapabilitiesAudioSessionPolicy` was designed to be used from call participants who don't actively participate in the call, but they may do in the future (e.g. Livestream viewers, Twitter Space listener etc)

### 🐞 Fixed
- When a call is being created from another device than the one starting the call, if you don't provide any members, the SDK will get the information from the backend [#660](https://github.com/GetStream/stream-video-swift/pull/660)
- The `OutgoingCallView` provided by the default `ViewFactory` implementation won't show the current user in the ringing member bubbles [#660](https://github.com/GetStream/stream-video-swift/pull/660)

### 🔄 Changed
- The provided `CallControls` and `CallTopView` component will now respect user's capabilities in order to show/hide the video, audio and toggleCamerat buttons. [#661](https://github.com/GetStream/stream-video-swift/pull/661) [#666](https://github.com/GetStream/stream-video-swift/pull/666)

# [1.16.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.16.0)
_January 31, 2025_

### ✅ Added
- You can now override the default `UserAvatar`, that is used across various SDK components, by using overriding the new `makeUserAvatar` method on your `ViewFactory` implementation. [#644](https://github.com/GetStream/stream-video-swift/pull/644)

### 🐞 Fixed
- Fix an issue that was causing the video capturer to no be cleaned up when the call was ended, causing the camera access system indicator to remain on while the `CallEnded` screen is visible. [#636](https://github.com/GetStream/stream-video-swift/pull/636)
- Fix an issue which was not dismissing incoming call screen if the call was accepted on another device. [#640](https://github.com/GetStream/stream-video-swift/pull/640)

# [1.15.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.15.0)
_January 14, 2025_

### ✅ Added
- CallKit availability policies allows you to control wether `Callkit` should be enabled/disabled based on different rules [#611](https://github.com/GetStream/stream-video-swift/pull/611)
- Support for setting a ringtone for CallKit calls [#628](https://github.com/GetStream/stream-video-swift/pull/628)
- Codec negotiation during calls (#606)(https://github.com/GetStream/stream-video-swift/pull/606)
- When moving to background/foreground while your video is active, if the device doesn't support [AVCaptureSession.isMultitaskingCameraAccessSupported](https://developer.apple.com/documentation/avfoundation/avcapturesession/ismultitaskingcameraaccesssupported) the SDK will mute/unmute the track to ensure that other participants have some feedback from your track. [#633](https://github.com/GetStream/stream-video-swift/pull/633)

### 🐞 Fixed
- By observing the `CallKitPushNotificationAdapter.deviceToken` you will be notified with an empty `deviceToken` value, once the object unregister push notifications. [#608](https://github.com/GetStream/stream-video-swift/pull/608)
- When a call you receive a ringing while the app isn't running (and the screen is locked), websocket connection wasn't recovered. [#600](https://github.com/GetStream/stream-video-swift/pull/600)
- Sorting order on Fullscreen Layout and Picture-in-Picture wasn't respecting dominant speaker change. [#613](https://github.com/GetStream/stream-video-swift/pull/613)

# [1.14.1](https://github.com/GetStream/stream-video-swift/releases/tag/1.14.1)
_November 12, 2024_

### 🐞 Fixed
- When joining one call after another, the last frame of the previous call was flashing for a split second in the new call [#596](https://github.com/GetStream/stream-video-swift/pull/596)

# [1.14.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.14.0)
_November 06, 2024_

### ✅ Added
- You can now provide the incoming video quality setting for some or all participants [#571](https://github.com/GetStream/stream-video-swift/pull/571)
- You can now set the time a user can remain in the call - after their connection disrupted - while waiting for their network connection to recover [#573](https://github.com/GetStream/stream-video-swift/pull/573)
- You can now provide the preferred Video stream codec to use [#583](https://github.com/GetStream/stream-video-swift/pull/583)
- Sync microphone mute state between the SDK and CallKit [#590](https://github.com/GetStream/stream-video-swift/pull/590)

### 🐞 Fixed
- Toggling the speaker during a call wasn't always working. [#585](https://github.com/GetStream/stream-video-swift/pull/585)
- In some cases when joining a call setup wasn't completed correctly which lead in issues during the call (e.g. missing video tracks or mute state not updating). [#586](https://github.com/GetStream/stream-video-swift/pull/586)

# [1.13.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.13.0)
_October 08, 2024_

### 🐞 Fixed

- Improved performance on lower end devices [#557](https://github.com/GetStream/stream-video-swift/pull/557)
- CallKitService access issue when ending calls [#566](https://github.com/GetStream/stream-video-swift/pull/566)

# [1.12.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.12.0)
_September 27, 2024_

### ✅ Added
- You can now pass your customData when initializing a `CallViewModel` [#530](https://github.com/GetStream/stream-video-swift/pull/530)

### 🔄 Changed
- Updated the default sorting for Participants during a call to minimize the movement of already visible tiles [#515](https://github.com/GetStream/stream-video-swift/pull/515)
- **Breaking** The `StreamDeviceOrientation` values now are `.portrait(isUpsideDown: Bool)` & `.landscape(isLeft: Bool)`. [#534](https://github.com/GetStream/stream-video-swift/pull/534)

### 🐞 Fixed
- An `MissingPermissions` error was thrown when creating a `StreamVideo` with anonymous user type. [#525](https://github.com/GetStream/stream-video-swift/pull/525)

# [1.10.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.10.0)
_August 29, 2024_

### ✅ Added
- Participants (regular and anonymous) count, can be accessed - before or after joining a call - from the `Call.state.participantCount` & `Call.state.anonymousParticipantCount` respectively. [#496](https://github.com/GetStream/stream-video-swift/pull/496)
- You can now provide the `CallSettings` when you start a ringing call [#497](https://github.com/GetStream/stream-video-swift/pull/497)

### 🔄 Changed
- The following `Call` APIs have been now marked as async to provide better observability.
    - `func focus(at point: CGPoint)`
    - `func addCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput)`
    - `func removeCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput)`
    - `func addVideoOutput(_ videoOutput: AVCaptureVideoDataOutput)`
    - `func removeVideoOutput(_ videoOutput: AVCaptureVideoDataOutput)`
    - `func zoom(by factor: CGFloat)`

# [1.0.9](https://github.com/GetStream/stream-video-swift/releases/tag/1.0.9)
_July 19, 2024_

### ✅ Added
- Support for custom participant sorting in the Call object. [#438](https://github.com/GetStream/stream-video-swift/pull/438)
- Ability to join call in advance with joinAheadTimeSeconds parameter. [#446](https://github.com/GetStream/stream-video-swift/pull/446)
- Missed calls support [#449](https://github.com/GetStream/stream-video-swift/pull/449)
- IncomingCallViewModel has been simplified and the `hideIncomingCallScreen` property as also the `stopTimer` have been removed. [#449](https://github.com/GetStream/stream-video-swift/pull/449)

# [1.0.8](https://github.com/GetStream/stream-video-swift/releases/tag/1.0.8)
_June 17, 2024_

### ✅ Added
- A new `ParticipantAutoLeavePolicy` that allows you to set when a user should automatically leave a call. [#434](https://github.com/GetStream/stream-video-swift/pull/434)

### 🔄 Changed

# [1.0.7](https://github.com/GetStream/stream-video-swift/releases/tag/1.0.7)
_June 10, 2024_

### ✅ Added
- Support for session timers. [#425](https://github.com/GetStream/stream-video-swift/pull/425)
- Rejecting call contains a reason parameter. [#428](https://github.com/GetStream/stream-video-swift/issues/428)

# [1.0.6](https://github.com/GetStream/stream-video-swift/releases/tag/1.0.6)
_May 30, 2024_

### ✅ Added
- In `CallKitService` you can now configure if calls support Video. Depending on the value `CallKit` will suffix either the word `Audio` (when false) or `Video` when true, next to the application's name. [#420](https://github.com/GetStream/stream-video-swift/pull/420)

# [1.0.5](https://github.com/GetStream/stream-video-swift/releases/tag/1.0.5)
_May 28, 2024_

### 🔄 Changed

# [1.0.4](https://github.com/GetStream/stream-video-swift/releases/tag/1.0.4)
_May 27, 2024_

### 🔄 Changed
- `CallKitAdapter` will dispatch voIP notification reporting to the MainActor. [#411](https://github.com/GetStream/stream-video-swift/pull/411)

# [1.0.3](https://github.com/GetStream/stream-video-swift/releases/tag/1.0.3)
_May 22, 2024_

### 🔄 Changed
- `Call` objects for the same `cId` will reference the same memory instance. [#404](https://github.com/GetStream/stream-video-swift/pull/404)
- `CallKitService.callEnded` now accepts the cId of the call to end. [#406](https://github.com/GetStream/stream-video-swift/pull/406)
- `CallKitService.State` has been deprecated. [#406](https://github.com/GetStream/stream-video-swift/pull/406)

### 🐞 Fixed
- Video tracks for anonymous users not displaying

# [1.0.2](https://github.com/GetStream/stream-video-swift/releases/tag/1.0.2)
_May 17, 2024_

### 🔄 Changed

### ✅ Added
- An `originalName` property on the `User` that will hold the name provided when initialized. [#391](https://github.com/GetStream/stream-video-swift/pull/391

# [1.0.1](https://github.com/GetStream/stream-video-swift/releases/tag/1.0.1)
_May 10, 2024_

### 🔄 Changed

### ✅ Added
- A viewModifier that allows you to present a view whenever a call ends. [#382](https://github.com/GetStream/stream-video-swift/pull/382)

# [1.0.0](https://github.com/GetStream/stream-video-swift/releases/tag/1.0.0)
_May 01, 2024_

### 🔄 Changed
- The return type of `call.get()` is now the API type `GetCallResponse` which encapsulates the previous `CallResponse` under the `call` property. [#335](https://github.com/GetStream/stream-video-swift/pull/335)
- Remove Nuke dependency from the SwiftUI SDK. [#340](https://github.com/GetStream/stream-video-swift/pull/340)
- `members` type changed from `MemberRequest` to `Member` in `startCall` and `enterLobby` in `CallViewModel`. [#368](https://github.com/GetStream/stream-video-swift/pull/368)

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
