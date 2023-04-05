---
title: UI customization
---

## UI components vs Custom

StreamVideo provides both ready made components to use directly in your app, as well as extension points that you can use to inject your own custom UI. If you just need the calling functionality and completely custom UI, you can use only our low-level client.

Let's explore the different possibilities and how they would impact your app and the integration efforts.

## Using only the low-level client

If your app needs a completely custom UI and calling flow, you can use only our low-level client that implements the WebRTC protocol and communicates with our backend services. If you go with this approach, you can either use our stateful `CallViewModel` that allows you to observe the call state (list of participants, camera & microphone state, etc), or use our lower level observable `Call` object and implement your own presentation objects.

Additionally, if you go with this approach, you can still use some components from our UI SDKs (if they fit your use-case), to facilitate your development. We have several examples for this in our cookbook. //TODO: figure out the correct link here, after the reorg.

This approach would require some familiarity with our low-level client, and the highest development efforts compared to the other two options. On the other hand, it gives you a maximum flexibility to customize the calling flow according to your needs.

In any case, our view components are highly customizable and flexible for many video/audio calling cases, and they can save big development efforts. Therefore, we recommend that you consider the other two options below, before deciding on starting from scratch.

## Mix & match

The mix & match approach is ideal if you need one of the standard calling flows, but with a possibility to replace parts of the UI with your own implementation. Our UI SDK allows you to completely swap views with your own custom interface elements.

For example, if you are building an app with incoming / outgoing calling screens, you can easily swap only those screens. For building your custom screens, you can still reuse our lower level components.

This approach provides a nice balance between levels of customization and development efforts. Find examples and extension slots to get started in our docs [here](../ui/view-slots.md).

## Simple theming

If you need a standard video calling experience that needs to match the rest of your app's look and feel, you can use our theming customizations.

This is the fastest way to add calling support to your app, just setup our video client and attach our `CallModifier` to your hosting view. You can change the fonts, colors, icons, texts and sounds used in the SDK, by interacting with our `Appearance` class.

You can find more details about how to customize the theming [here](../ui/ui-overview.md).
