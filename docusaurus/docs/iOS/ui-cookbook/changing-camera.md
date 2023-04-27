---
title: Changing Camera
---

The StreamVideo iOS SDK supports toggling between the front and back camera of the iOS device while in a call.

There are two ways to change the camera, depending on whether you use the `CallViewModel` or the `Call` object directly.

#### Toggle the camera with the `CallViewModel`

You can toggle the camera position by calling the method `toggleCameraPosition`. The method takes into consideration the current camera state (front or back), and it updates it to the new one.

```swift
viewModel.toggleCameraEnabled()
```

#### Toggle the camera with the `Call` object

If you have your own presentation layer and want to directly handle the camera state, you can use the `Call` object directly to update the state. In order to do this, you should use the `changeCameraMode(position: CameraPosition, completion: @escaping () -> ())` method:


```swift
call.changeCameraMode(position: .back) {
	print("changed camera position")
}
```