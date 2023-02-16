---
title: Overview
slug: /
---

// TODO: provide a polished image here

## Introduction

The StreamVideo product consists of three separate SDKs:

- low-level client - responsible for establishing calls, built on top of WebRTC.
- SwiftUI SDK - SwiftUI components for different types of call flows.
- UIKit SDK - UIKit wrapper over the SwiftUI components, for easier usage in UIKit based apps.

The low-level client is used as a dependency in the UI frameworks, and can also be used standalone if you plan to build your own UI. The UI SDKs depend on the low-level client.

:::note
For more info about the architecture, go to our [Architecture Overview](./architecture-overview.md).
:::

## Getting started

If you want to know where to get started with coding right away, we have a lot of great resources for you:

- [Quick start](quick-start.md): Build your first app with video
- [Chat Integration](../guides/chat-integration.md): Learn how to integrate chat in your video applications
- [Custom Video Filters](../guides/custom-filters.md): Enhance video capabilities with custom filters
- COMING SOON: Sample Application: See an entire codebase filled with best practices and examples how to integrate video (and chat)

// TODO: Add more resources here how to get started

## Main Principles

Our SDK follows a few principles:

- Progressive disclosure: The SDK can be used easily with very minimal knowledge of it. As you become more familiar with it, you can dig deeper and start customizing it on all levels.
- Swift native API: Uses Swift's powerful language features to make the SDK usage easy and type-safe.
- Familiar behavior: The UI elements are good platform citizens and behave like native elements; they respect `tintColor`, padding, light/dark mode, dynamic font sizes, etc.
- Fully open-source implementation: You have access to the complete source code of the SDK on GitHub.

If you want to learn more about our principles and architecture, head over to the [Architecture Overview](./architecture-overview.md) page.

## How to use our documentation

We know that everyone consumes documentation differently, which is why we want to make sure everyone can reach their goals as fast as possible.

- Go through it sequentially and look at the next pages (heading to [Installation](./install.md) next) to get a thorough introduction that covers the most important topics and gets you up to speed in the quickest way.
- Search for a specific problem using the search bar at the top, getting guided there directly.
- Explore our guides where we cover the more advanced topics that you might encounter, for example [CallKit integration](../guides/callkit-integration.md), [Custom Filters](../guides/custom-filters.md), and [Deep Linking](../guides/deep-linking.md).

:::tip
Did you know that you can also use the keyboard command _CMD + K_ to open up the search bar. Try it now and feel like a pro.
:::
