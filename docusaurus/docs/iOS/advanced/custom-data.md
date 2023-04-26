---
title: Custom Data
---

Custom data is additional information that can be added to the default data of Stream. It is a dictionary of key-value pairs that can be attached to users, events, and pretty much almost every domain model in the Stream SDK.

On iOS, the custom data is represented by the following dictionary, `[String: RawJSON]`. The `RawJSON` is an enum that can be represented by different types of values. It can be a String, Number, Boolean, Array, Dictionary, or null. In the end, this is to make the dictionary strongly typed so that it is safer and easier to use. The code snippet below shows the simplified implementation of RawJSON.

```swift
indirect enum RawJSON: Codable, Hashable {
    case number(Double)
    case string(String)
    case bool(Bool)
    case dictionary([String: RawJSON])
    case array([RawJSON])
}
```