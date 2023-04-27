---
title: Custom Data
---

Custom data is additional information that can be added to the default data of Stream. It is a dictionary of key-value pairs that can be attached to users, events, and pretty much almost every domain model in the Stream SDK.

On iOS, the custom data is represented by the following dictionary, `[String: RawJSON]`. The `RawJSON` is an `enum` that can be represented by different types of values. It can be a String, Number, Boolean, Array, Dictionary, or null. In the end, this is to make the dictionary strongly typed so that it is safer and easier to use. The code snippet below shows the simplified implementation of `RawJSON`.

```swift
indirect enum RawJSON: Codable, Hashable {
    case number(Double)
    case string(String)
    case bool(Bool)
    case dictionary([String: RawJSON])
    case array([RawJSON])
}
```

## Adding Custom Data

Adding extra data can be done through the Server-Side SDKs or through the Client SDKs. In the iOS Stream Video SDK, you can add extra data when creating/updating a user, event, reaction and other models. 
As a simple example, let's see how you can add a new email field to the user.

```swift
let userInfo = User(
    id: id,
    name: name,
    imageURL: imageURL,
    customData: ["email": .string("test@test.com")]
)
```

## Reading Custom Data

All of the most important domain models in the SDK have an `customData` property that you can read the additional information added by your app.

The following code snippet shows how to get an email from a user's custom data.

```swift
let email = user.customData["email"]?.stringValue ?? ""
print(email)
```

:::tip
In order to access the email even more easily, you can extend our models to provide an extra property, in this case, you can add an `email` property to the `User` model like this:
```swift
extension User {
    var email: String? {
        customData["email"]?.stringValue
    }
}
```
:::

To see how you can get data with different types from custom data, we can pick the example of the ticket information again and see how you can get it from custom data.

```swift
let ticket = user.customData["ticket"]?.dictionaryValue
let name = ticket?["name"]?.stringValue ?? ""
let price = ticket?["price"]?.doubleValue ?? 0.0
```

As you can see above, each type of value can be easily accessible from an custom data property. The SDK will try to convert the raw type to a strongly typed value and return it if the property exists, and if the type is correct. Below is the list of all values supported:

- `stringValue: String?`
- `numberValue: Double?`
- `boolValue: Bool?`
- `dictionaryValue: [String: RawJSON]?`
- `arrayValue: [RawJSON]?`
- `stringArrayValue: [String]?`
- `numberArrayValue: [Double]?`
- `boolArrayValue: [Bool]?`